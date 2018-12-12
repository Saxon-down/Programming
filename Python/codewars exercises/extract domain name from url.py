all_domains = [
    "http://www.mydomain.com/blah:1234",
    "http://saxon-down.com",
    "http://github.com/carbonfive/raygun",
    "www.rabbit.here"
]
for domain_name in all_domains :
    if domain_name.find("/") > 0 :
        domain = ((domain_name.split("/"))[2]).split(".")[-2]
    else :
        domain = domain_name.split(".")[-2]
    print(domain)