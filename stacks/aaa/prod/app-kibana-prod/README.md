this stack is defunct but left here for reference

had a lot of troubles getting this talking to the Elasticsearch set up in the aaaops network. Network path was clear - the issue was getting the auth working. Configuring kibana via the environment was also difficult (xpack is a 'list of objects' in the config, and the docs don't mention how to configure that via env).

there also seems to be a bug in the current release of kibana's official container on dockerhub that prevents it from bootstrapping a new install properly https://discuss.elastic.co/t/definition-of-plugin-urlforwarding-not-found-and-may-have-failed-to-load/349921 (likely works on an existing install)


env vars before pulling the pin

```
SERVER_NAME=cloudlogs.aaa.tools
SERVER_PORT=8080     # port + this stack's healthcheck need to match
ELASTICSEARCH_HOSTS='["http://logdbaws.aaa.tools:9200"]'
#ELASTICSEARCH_SERVICEACCOUNT_TOKEN=AAEAAWVsYXN0aWMva2liYW5hL2xvZ3M6dnU1dHdxNVFUd3FiY1NJUV9DSHMxQQ   # this token is now dead
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=changeme  # default ES super password
```

see notes in README in aaaops/prod/ec2-logdbaws