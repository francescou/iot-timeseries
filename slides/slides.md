# TSDBs for the Internet of Things

## Linux Day 2016 Roma

--

### who am I?

Francesco Uliana

Technologist @ CNR

@warrior10111

<http://www.uliana.it/francesco>

\#java, \#functionalprogramming \#devops \#IoT

--

# Internet of Things


### Internet of Things

#### "Internet"

- communication protocols
- interoperability


### Internet of Things

#### "Things"

- HW devices
- sensors
- actuators


### IoT devices

![nest](https://cdn1.pcadvisor.co.uk/cmsdata/reviews/3543915/nest-3rd-gen-review_thumb800.jpg)


### IoT devices

- Nest, Netatmo
- anti-theft systems
- fitness trackers
- domotics


### IoT DIY

![nodemcu](https://statics3.seeedstudio.com/images/113990105%201.jpg)


### IoT DIY

- Arduino
- Raspberry pi
- NodeMCU


### Key characteristics

- sensors
- actuators
- low consumption
- disposable

--

# Architecture


### Client/Server - star topology

- Client
  + *DUMB* IoT devices
- Server
  + security/authentication
  + persistent data storage
  + service interoperability (e.g. SMS, social network)
  + HA


### P2P

- P2P means devices communication directly with each other.
- No need for mediation.
- The garage sensor needs to open the lights in the house and start the heating? Sure thing – it just tells them to do so. No need to go through the cloud.

- PROs: scale, low latency

--

# Time series


### Time series

A time series is a **series** of **data points** indexed in **time order**.

![time series](http://www.fromthebottomoftheheap.net/assets/img/posts/additive-modeling-global-temperature-series-revisited-plot-temperature-data-1.png)


### Data points

```
stock,symbol=AAPL bid=127.46,ask=127.48
stock,symbol=GOOGL bid=821.63,ask=821.65
```

- measurement: stock
- tags: AAPL
- fields
  - bid = 127.46
  - ask = 127.48


### Data points

`temperature,machine=unit42,type=assembly external=25,internal=37 1434067467000000000`


### Tools ?

- persist data on device storage
- make data avaiable to allow:
  + dashboard
  + alerting
- caveat: big data


### Tools ?

#### rDBMS


### RDBMS - tradeoffs

- data volume
- query language
- CR~~UD~~

```
SELECT
...
GROUP BY
DATEPART(YEAR, DT.[Date]),
DATEPART(MONTH, DT.[Date]),
DATEPART(DAY, DT.[Date]),
DATEPART(HOUR, DT.[Date]),
(ROUND((DATEPART(MINUTE, DT.[Date]) / 5),0,1) * 5)
```

--

### Tools

#### TimeSeries DataBases (TSDB)

- optimized for handling **time series** data **indexed by time**


### Query Language

#### examples

```
select nymex/gold_price * nymex/gold_volume

select sum( onpeak( powerusagekwh ) ) * energy_charge
```


### List of time series databases

- Graphite
- InfluxDB
- OpenTSDB
- Riak-TS


![tsdb popularity](https://influxdata.com/wp-content/uploads/2016/04/wit8.png)

--
# Database


### InfluxDB

- Go
- optimized for fast, high-availability storage and retrieval of time series data in fields
- operations monitoring, application metrics, Internet of Things sensor data, and real-time analytics.


### Lab

#### environment setup

- Raspbian Jessie LITE
- cUrl
- jq
- wget
- NodeJS
- vim


### Setup

```bash
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -

sudo apt-get install -y curl jq wget nodejs htop vim
```


### Wget

```bash
mkdir lug-workshop && cd $_

# download ARM builds from https://www.influxdata.com/downloads/

```


### Lab

#### setup InfluxDB

```bash
sudo tar xvf influxdb-1.0.2_linux_armhf.tar.gz \
  -C / --strip-components=2

sudo chown -R pi /var/lib/influxdb/

influxd
```

<https://docs.influxdata.com/influxdb/v1.0/introduction/installation/>


### Lab - Influx CLI

```
$ influx
Connected to http://localhost:8086 version 1.0.x
InfluxDB shell 1.0.x
```

    > CREATE DATABASE mydb

    > SHOW DATABASES

    > USE mydb

    > INSERT cpu,host=serverA,region=us_west value=0.64

```
<measurement>[,<tag-key>=<tag-value>...] <field-key>=<field-value>[,<field2-key>=<field2-value>...] [unix-nano-timestamp]
```


### HTTP

- TCP port **8083** is used for InfluxDB’s **Admin panel**
- TCP port **8086** is used for client-server communication over InfluxDB’s **HTTP API**


### Getting started

<http://raspberrypi:8083/>

`show measurements`

`select time,req from httpd`


### Lab - query

`> SELECT "host", "region", "value" FROM "cpu"`


### Lab

#### multiple fields

```
> INSERT temperature,machine=unit42,type=assembly
  external=25,internal=37

> SELECT * FROM "temperature"

> SELECT * FROM "cpu_load_short" WHERE "value" > 0.9
```


### Lab - advanced queries

<https://docs.influxdata.com/influxdb/v1.0/query_language/data_exploration/>

```
> SELECT COUNT("water_level") FROM "h2o_feet" \
      WHERE time >= '2015-08-19T00:00:00Z' \
      AND time <= '2015-08-27T17:00:00Z' \
      AND "location"='coyote_creek' GROUP BY time(3d)
```


### Lab - HTTP API

#### writing data

```bash
curl -i -XPOST http://localhost:8086/query --data-urlencode \
  "q=CREATE DATABASE mydb"

curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary \
  'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000'
```


### Important

InfluxDB is a **schemaless database**.

You can add new measurements, tags, and fields at any time.

Note that if you attempt to write data with a different type than previously used (for example, writing a string to a field that previously accepted integers), InfluxDB will reject those data.


### Lab - HTTP API

#### reading data

```
curl -GET 'http://raspberrypi:8086/query?pretty=true' \
  --data-urlencode "db=mydb" --data-urlencode \
  "q=SELECT \"value\" FROM \"cpu_load_short\" WHERE \"region\"='us-west'" \
  | jq '.results[0].series'
```


### Advanced concepts

- InfluxDB can handle hundreds of thousands of data points per second.
- over a long period of time can create storage concerns.
- A natural solution is to downsample the data

- Continuous Queries
- Retention Policies

--

# Ingestion


### Ingestion

#### Telegraf - TIME-SERIES DATA COLLECTION

![telegraf](https://influxdata.com/wp-content/uploads/2015/12/statsd-telegraf.png)


### Telegraf - TIME-SERIES DATA COLLECTION
- open source agent written in Go
- collecting metrics and data on the system it's running on or from other services.
- Telegraf writes data it collects to InfluxDB in the correct format.
- plugin-driven server agent for collecting & reporting metrics


### Telegraf - input plugin

- input plugins to
    + source a variety of metrics directly from the system it’s running on
    + pull metrics from third party APIs
    + listen for metrics via a statsd and Kafka consumer services


### Telegraf - output plugins

- output plugins to send metrics to a variety of other datastores, services, and message queues, e.g.:
    - InfluxDB
    - Graphite
    - OpenTSDB
    - Kafka
    - MQTT
    - ...


### Lab - Telegraf setup

```bash
sudo tar  xvf telegraf-1.0.1_linux_armhf.tar.gz \
  -C / --strip-components=2

telegraf -sample-config > telegraf.conf
```

<https://docs.influxdata.com/telegraf/v1.0/introduction/installation/>



### telegraf.conf

    [[outputs.influxdb]]
      url = "http://localhost:8086" # required.
      database = "telegraf" # required.
      precision = "s"

    [[inputs.cpu]]
      percpu = true
      totalcpu = false
      # filter all fields beginning with 'time_'
      fielddrop = ["time_*"]

`telegraf -config telegraf.conf`


### Lab - OS metrics

`select load1 from system`

`python2 t_evil.py`

<https://github.com/francescou/iot-timeseries/blob/master/t_evil.py>


### Lab - custom ingestion

#### HTTP JSON Plugin

<https://github.com/influxdata/telegraf/tree/master/plugins/inputs/httpjson>

e.g. github API <https://api.github.com/repos/jquery/jquery>

--

# Visualization


### Grafana

- Beautiful metric & analytic dashboards
- The leading tool for querying and visualizing time series and metrics
- 12K+ Github stars and counting...
- pluggable panels and data sources
- built in support for many of the most popular time series data sources.


![grafana screenshot](http://grafana.org/assets/img/features/dashboard_ex1.png)


### Lab - Grafana setup

- no ARM build
- Grafana unofficial packages for arm: <https://github.com/fg2it/grafana-on-raspberry>
- <http://docs.grafana.org/installation/configuration/>


### Lab - Grafana setup

```bash
mkdir grafana

tar xvf grafana-3.1.1-1472506485.linux-arm.tar.gz \
  -C grafana/ --strip-components=1

./bin/grafana-server
```


### Lab - Grafana quickstart

- influxDB datasource <http://docs.grafana.org/datasources/influxdb/>
- mean, standard deviation
- ~~alerting~~
- install plugin <https://grafana.net/plugins>
  + pie chart (sum blocked/running processes)

--

# Alerting


### Kapacitor

- TIME SERIES DATA PROCESSING, MONITORING, & ALERTING

![kapacitor](https://media.licdn.com/mpr/mpr/shrinknp_800_800/AAEAAQAAAAAAAAQFAAAAJGQ3ZDNiZGU2LTVlNjAtNDFjYi04MjYxLTBiNGFjYjVhMjYzNQ.png)


### Kapacitor

- can process both stream and batch data from InfluxDB
- Add custom user defined functions to detect anomalies
- Integrates with HipChat, OpsGenie, Alerta, Sensu, PagerDuty, Slack and VictorOps


### Lab - Kapacitor

```bash
sudo tar xvf kapacitor-1.0.2_linux_armhf.tar.gz \
  -C / --strip-components=2

kapacitord config > kapacitor.conf

kapacitord -config kapacitor.conf
```


### Lab - cpu_alert.tick

<https://github.com/francescou/iot-timeseries/blob/master/loadaverage.tick>

    stream
        // Select just the cpu measurement from our example database.
        |from()
            .database('telegraf')
            .measurement('cpu')
        |alert()
            .crit(lambda: "usage_idle" <  70)
            // Whenever we get an alert write it to a file.
            .log('/tmp/alerts.log')


### Lab - cpu_alert.tick

```bash
kapacitor define cpu_alert
        -type stream
        -tick cpu_alert.tick
        -dbrp mytelegraf.autogen

kapacitor enable cpu_alert

tail -f /tmp/alerts.log
```


### Lab - kapacitor custom alert

<https://docs.influxdata.com/kapacitor/v1.0/introduction/getting_started/#trigger-alert-from-stream-data>

--

# MQTT


![mqtt stack](http://www.hivemq.com/wp-content/uploads/mqtt-tcp-ip-stack.png)


![mqtt flow](http://www.hivemq.com/wp-content/uploads/connect-flow.png)


### MQTT - broker

#### Mosca

<https://github.com/mcollina/mosca/wiki/Mosca-as-a-standalone-service.>

`$ npm install -g mosca bunyan`

`$ mosca -v | bunyan`


### MQTT - client

#### MQTT.js

`npm install -g mqtt`

`mqtt publish -t /topic -m hello`


### MQTT - client

<https://nodemcu.readthedocs.io/en/master/en/modules/mqtt/>

<https://github.com/francescou/iot-timeseries/blob/master/led.lua>

```lua
LED_PIN = 1

m = mqtt.Client("nodemcu", 120)

function printMessage(client, topic, data)

  gpio.mode(LED_PIN, gpio.OUTPUT)
  gpio.write(LED_PIN, gpio.HIGH)
  tmr.delay(500 * 1000)
  gpio.write(LED_PIN, gpio.LOW)

  print(topic .. ":" )
  if data ~= nil then
    print(data)
  end
end

function connected(client)
  print("connected")
  m:on("message", printMessage)
  m:subscribe("/led",0, function(client) print("subscribe success") end)

  tmr.alarm(1, 1000, 1, function()
    value = adc.read(0)
    m:publish("/light",value ,0,0, function(client) print("sent") end)
  end)

end

function showError(client, reason)
  print("failed reason: "..reason)
end

m:connect("193.204.163.219", 1883, 0, connected, showError)
```


### LDR NodeMCU

![LDR NodeMCU](http://www.childs.be/data/uploads/Light_bb.jpg)


### NodeMCU - ADC

#### Analog digital converter

```lua
value = adc.read(0)
print(value)
 -- send data
```

--

# Lab


### Ingestion

NodeMCU -> MQTT -> Telegraf -> InfluxDB

enable `inputs.mqtt_consumer`


### Alerting

InfluxDB -> Kapacitor -> MQTT -> NodeMCU

--

### Lab (bonus)

implement a watchdog for `t_evil.py`

`....post("http://example.com/api/alert")`


# Watchdog

<https://github.com/francescou/iot-timeseries/blob/master/watchdog.py>

--

# Conclusions


### Not only IoT

- devops
  + metrics
- data science
- real time analytics
- microservices polyglot persistence
- time series analysis and forecasting


### Alternatives

- Elasticsearch + Kibana + Timelion
- Prometheus
- OpenTSDB
--

### Resources

- <http://jmoiron.net/blog/thoughts-on-timeseries-databases>
- <https://www.influxdata.com/use-cases/iot-and-sensor-data/>
- <http://db-engines.com/en/ranking/time+series+dbms>
- <https://blog.dataloop.io/top10-open-source-time-series-databases>
- <https://prometheus.io/blog/2016/07/23/pull-does-not-scale-or-does-it/>