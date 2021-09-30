FROM python:3.9.7
ADD  src  /src/
RUN pip install kopf kubernetes  -i https://mirrors.aliyun.com/pypi/simple/
CMD bash -x  /src/start.sh
