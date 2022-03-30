#!/bin/bash
pip install -t . msal==1.6.0 python-json-logger==2.0.1 requests==2.25.0
curl -L https://github.com/ausseabed/product-catalogue/archive/master.zip -o master.zip
unzip master.zip 
mv product-catalogue-master/py-rest-client/product_catalogue_py_rest_client .
rm -rf master.zip product-catalogue-master