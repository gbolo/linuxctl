 curl -XPUT 127.0.0.1:9200/_template/iis_template -d '{
        "template" : "iis-*",
        "settings" : {
          "index.refresh_interval" : "5s"
        },
        "mappings" : {
          "iis" : {
             "properties" : {
              "@version" : {
                "index" : "not_analyzed",
                "type" : "string"
              },
              "datetime_orig" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "iis-app" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "iis-id" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "server" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "message" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "server_ip" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "method" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "uri_stem" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "uri_query" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "server_port" : {
                "index": "not_analyzed",
                "type" : "integer"
              },
              "cs-username" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "client_ip" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "user_agent" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "tags" : {
                "type" : "string"
              },
              "virtual_host" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "status" : {
                "index": "not_analyzed",
                "type" : "string"
              },
              "bytes_recv" : {
                "index": "not_analyzed",
                "type" : "integer"
              },
              "bytes_sent" : {
                "index": "not_analyzed",
                "type" : "integer"
              },
              "time_taken_ms" : {
                "index": "not_analyzed",
                "type" : "integer"
              },
              "win32_status" : {
                "index": "not_analyzed",
                "type" : "integer"
              },
              "type" : {
                "index": "not_analyzed",
                "type" : "string"
              }
            }
          }
        },
        "aliases" : { }
      }'


