
## About this folder
In this folder you find an example of generating certificate signing request via wrapper aronund certreq.exe. Then how to generate .crt file from that .csr

Pay special attention to generating CSR - you need to select correct template name which you should get assigned by your ICA admin and you need to correctly list all the hostnames under which your server is reachable. 

Install the .crt file to the Personal certificates of your computer. 


**The SQL server service account needs to have FULL permissions onto the certificate.**


On the SQL server's side of configuration, you need to select the certificate in the properties of the SQL server service. 