import httpClient
import xmltree
import xmlparser


when isMainModule:
  let client = newHttpClient()
  client.headers = newHttpHeaders( {"Content-Type": "text/xml"} )

  var method_name = newElement("methodName")
  method_name.add newText("getSystemState")

  var value = newElement("value")
  value.add newText("caller_id") 

  var params = newElement("params")
  params.add value

  let body = newXmlTree("methodCall", [method_name, params])

  # let body = """
  # <methodCall>
  #   <methodName>getSystemState</methodName>
  #   <params><value>caller_id</value></params>
  # </methodCall>
  # """

  const master_uri = "http://localhost:11311/RPC2"

  try:
    let response = client.postContent(master_uri, body = $body)
    let response_xml = parseXml(response)
    # echo response_xml.child("params")
    let data_xml =  response_xml.child("params")
                    .child("param")
                    .child("value")
                    .child("array")
                    .child("data")

    for value_xml in data_xml:
      if value_xml[0].tag == "array":  
        for val in value_xml[0].child("data"):      
          echo val.innerText
  except OSError:
    echo "OS Error!"
  
  client.close()
