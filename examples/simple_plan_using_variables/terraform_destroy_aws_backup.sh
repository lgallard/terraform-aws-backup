#!/bin/sh
targets=""
for i in `terraform state list | grep "selection"`; do targets="${targets} --target=${i}"; done

# Destroy selections
terraform destroy ${targets} 

# Destroy all
terraform destroy 
