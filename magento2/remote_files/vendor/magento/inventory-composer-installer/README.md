# Magento Inventory Composer Installer

Magento Inventory Composer Installer helps ot install modules that belongs to Magento [Multi Source Inventory](https://github.com/magento-engcom/msi/wiki) community project.

To enable simple **upgrade** for existing Magento installations MSI modules will be disabled by default. To enable them please use `magento module:enable` command. For more information please reference to [Magento Developers Documentation](https://devdocs.magento.com/guides/v2.2/install-gde/install/cli/install-cli-subcommands-enable.html).

For fresh Magento **installation** this plugin won't take effect so MSI modules will preserve default behavior. Thereby, they will be installed and enabled if other not configured explicitly.