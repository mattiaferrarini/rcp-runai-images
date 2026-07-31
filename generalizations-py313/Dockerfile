ARG BASE_IMAGE="ghcr.io/mattiaferrarini/dlab-runai-images/base-py313:master"
FROM ${BASE_IMAGE}

# Copy requirements
COPY generalizations-py313/requirements.txt /tmp/requirements.txt

# Install ripserplusplus from a patched source tarball for CUDA 12.x toolchains.
RUN apt-get update && \
	apt-get install -y --no-install-recommends cmake && \
	printf '%s\n' \
	"import hashlib, json, pathlib, urllib.parse, urllib.request" \
	"data = json.load(urllib.request.urlopen('https://pypi.org/pypi/ripserplusplus/1.1.2/json'))" \
	"sdists = [entry for entry in data['urls'] if entry.get('packagetype') == 'sdist']" \
	"assert sdists, 'No sdist found for ripserplusplus==1.1.2'" \
	"sdist = sdists[0]" \
	"url = sdist['url']" \
	"parsed = urllib.parse.urlparse(url)" \
	"assert parsed.scheme == 'https', f'Unexpected scheme: {parsed.scheme}'" \
	"assert parsed.netloc in {'files.pythonhosted.org', 'pypi.org'}, f'Unexpected host: {parsed.netloc}'" \
	"out = '/tmp/ripserplusplus-1.1.2.tar.gz'" \
	"urllib.request.urlretrieve(url, out)" \
	"expected = sdist.get('digests', {}).get('sha256')" \
	"assert expected, 'Missing SHA256 digest in PyPI metadata'" \
	"actual = hashlib.sha256(pathlib.Path(out).read_bytes()).hexdigest()" \
	"assert actual == expected, f'SHA256 mismatch: {actual} != {expected}'" \
	> /tmp/download_verify_rpp.py && \
	python3 /tmp/download_verify_rpp.py && \
	tar -xzf /tmp/ripserplusplus-1.1.2.tar.gz -C /tmp && \
	sed -i '/#include <thrust\/unique.h>/a #include <thrust\/sort.h>' /tmp/ripserplusplus-1.1.2/ripserplusplus/ripser++.cu && \
	uv pip install --no-cache /tmp/ripserplusplus-1.1.2 && \
	rm -rf /tmp/download_verify_rpp.py /tmp/ripserplusplus-1.1.2 /tmp/ripserplusplus-1.1.2.tar.gz /var/lib/apt/lists/*

# Install dependencies directly into the base image's venv
RUN uv pip install --no-cache -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok
