COMMON_OVERLAYS = tkl-webcp apache
COMMON_CONF = apache-vhost apache-credit tkl-webcp apache-ssl

CREDIT_ANCHORTEXT = Znuny Appliance
NONFREE = yes

include $(FAB_PATH)/common/mk/turnkey/mysql.mk
include $(FAB_PATH)/common/mk/turnkey.mk
