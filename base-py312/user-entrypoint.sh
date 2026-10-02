#!/bin/sh

set -e

# start sshd
service ssh start

# Setup GASPAR USER
GASPAR_USER=$(awk -F '-' '{ print $3 }' /var/run/secrets/kubernetes.io/serviceaccount/namespace)

if ! id -u $GASPAR_USER > /dev/null 2>&1; then
    echo "**** Creating GASPAR USER ****"
    GASPAR_UID=$(ldapsearch -H ldap://scoldap.epfl.ch -x -b "ou=users,o=epfl,c=ch" "(uid=$GASPAR_USER)" uidNumber | egrep ^uidNumber | awk '{ print $2 }')
    GASPAR_GID=$(ldapsearch -H ldap://scoldap.epfl.ch -x -b "ou=users,o=epfl,c=ch" "(uid=$GASPAR_USER)" gidNumber | egrep ^gidNumber | awk '{ print $2 }')
    GASPAR_SUPG=$(ldapsearch -LLL -H ldap://scoldap.epfl.ch -x -b ou=groups,o=epfl,c=ch \(memberUid=${GASPAR_USER}\) gidNumber | grep 'gidNumber:' | awk '{ print $2 }' | paste -s -d' ' -)


    # Create Groups
    for gid in $GASPAR_SUPG; do
        GROUP_NAME=$(ldapsearch -LLL -H ldap://scoldap.epfl.ch -x \
            -b ou=groups,o=epfl,c=ch "(gidNumber=$gid)" cn | awk '/^cn:/ {print $2}')

        # If the name is longer than 32 chars, shorten deterministically
        if [ ${#GROUP_NAME} -gt 32 ]; then
            # Keep first 24 chars, append 8-char hash to avoid collisions
            GRPNM=$(echo "$GROUP_NAME" | cut -c1-29)
        else
            GRPNM=$GROUP_NAME
        fi

        if ! getent group "$GRPNM" > /dev/null 2>&1; then
            groupadd -g "$gid" "$GRPNM"
        else
            groupmod -g "$gid" "$GRPNM"

        fi
    done

    # Determine the user's home directory. Derived images can set
    # USER_HOME_ROOT to a lab-specific shared storage mount.
    SCRATCH=dlabscratch1
    HOME_IS_EPHEMERAL=0
    if [ -n "${USER_HOME_ROOT:-}" ]; then
        USER_HOME="${USER_HOME_ROOT%/}/${GASPAR_USER}"
        if [ ! -d "$USER_HOME" ]; then
            echo "Error: Configured home directory does not exist: $USER_HOME"
            echo "Mount the lab storage at $USER_HOME_ROOT before starting the container."
            exit 1
        fi
    elif [ -d "/$SCRATCH/$GASPAR_USER" ]; then
        USER_HOME="/$SCRATCH/$GASPAR_USER"
    elif [ -d "/mnt/$SCRATCH/$GASPAR_USER" ]; then
        # Mounted on /mnt/dlabscratch1 -> retain the historical home path.
        if [ ! -e "/$SCRATCH" ]; then
            ln -s "/mnt/$SCRATCH" "/$SCRATCH"
            USER_HOME="/$SCRATCH/$GASPAR_USER"
        else
            USER_HOME="/mnt/$SCRATCH/$GASPAR_USER"
        fi
    else
        USER_HOME="/home/${GASPAR_USER}"
        mkdir -p "$USER_HOME"
        HOME_IS_EPHEMERAL=1
    fi

    # Create User and add to groups
    useradd -u ${GASPAR_UID} -d $USER_HOME -s /bin/bash ${GASPAR_USER} -g ${GASPAR_GID}
    usermod -aG $(echo $GASPAR_SUPG | tr ' ' ',') ${GASPAR_USER}
    if [ "$HOME_IS_EPHEMERAL" -eq 1 ]; then
        chown ${GASPAR_USER}:${GASPAR_GID} "$USER_HOME"
    fi

    # passwordless sudo
    echo "${GASPAR_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    # HACKYYYY: set automatic bash login
    echo "exec gosu ${GASPAR_USER} /bin/bash" > /root/.bashrc


    # .bashrc for user
    chown ${GASPAR_USER}:${GASPAR_GID} /tmp/.bashrc
    su ${GASPAR_USER} -c "if [ ! -f "$USER_HOME/.bashrc" ]; then cp /tmp/.bashrc '$USER_HOME/.bashrc'; fi"
fi


# Find correct USER_HOME if it's undefined
if [ -z "$USER_HOME" ]; then
    if [ -n "${USER_HOME_ROOT:-}" ] && [ -d "${USER_HOME_ROOT%/}/$GASPAR_USER" ]; then
        USER_HOME="${USER_HOME_ROOT%/}/$GASPAR_USER"
    elif [ -d "/dlabscratch1/$GASPAR_USER" ]; then
        USER_HOME="/dlabscratch1/$GASPAR_USER"
    elif [ -d "/mnt/dlabscratch1/$GASPAR_USER" ]; then
        USER_HOME="/mnt/dlabscratch1/$GASPAR_USER"
    elif [ -d "/home/$GASPAR_USER" ]; then
        USER_HOME="/home/$GASPAR_USER"
    else
        echo "Error: Unable to find a valid home directory for $GASPAR_USER"
        exit 1
    fi
fi

echo "USER_HOME: $USER_HOME"

# Update existing .bashrc to conditionally run 'dlab' command (otherwise there are annoying errors)
if su ${GASPAR_USER} -c "[ -f '$USER_HOME/.bashrc' ]"; then
    su ${GASPAR_USER} -c "sed -i '/^dlab$/c\command -v dlab >/dev/null 2>&1 && dlab' '$USER_HOME/.bashrc'"
fi

if [ -z "$1" ]; then
    exec gosu ${GASPAR_USER} /bin/bash -c "source ~/.bashrc && exec /bin/bash"
else
    echo "**** Executing '/bin/bash -c \"$*\"' ****"
    exec gosu ${GASPAR_USER} /bin/bash -c "source ~/.bashrc && exec /bin/bash -c \"$*\""
fi
