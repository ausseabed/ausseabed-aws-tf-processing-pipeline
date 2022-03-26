#!/bin/bash
pip install -t . msal python-json-logger requests boto3
curl -L https://github.com/ausseabed/product-catalogue/archive/master.zip -o master.zip
unzip master.zip 
mv product-catalogue-master/py-rest-client/product_catalogue_py_rest_client .
rm -rf master.zip product-catalogue-master