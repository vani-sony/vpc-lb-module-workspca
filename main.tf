module "vpc1" {
source = "./modules" 
region = var.region
vpccidr = var.vpccidr
publicsubn1 = var.publicsubn1
publicsubn2 = var.publicsubn2
privatesubn1 = var.privatesubn1
privatesubn2 =  var.privatesubn2
publiroute = var.publiroute
privroute = var.privroute
lbtype = var.lbtype
lt_type = var.lt_type
lt_amiid = var.lt_amiid
}
