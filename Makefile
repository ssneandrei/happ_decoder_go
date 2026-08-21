include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-happ-decoder
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-happ-decoder
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for Happ Decoder
  DEPENDS:=+happ-decoder
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/luci-app-happ-decoder/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/happ-decoder $(1)/etc/config/happ-decoder

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/happ-decoder $(1)/etc/init.d/happ-decoder

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-happ-decoder.json $(1)/usr/share/luci/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-happ-decoder.json $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/happ-decoder
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/happ-decoder/overview.js $(1)/www/luci-static/resources/view/happ-decoder/
endef

$(eval $(call BuildPackage,luci-app-happ-decoder))
