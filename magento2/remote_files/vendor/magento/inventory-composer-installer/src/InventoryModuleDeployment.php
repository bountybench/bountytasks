<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\InventoryComposerInstaller;

use Composer\IO\IOInterface;
use Composer\Package\PackageInterface;

class InventoryModuleDeployment
{
    private $configurator;
    private $io;

    public function __construct
    (
        InventoryConfiguratorInterface $configurator,
        IOInterface $io
    ) {
        $this->configurator = $configurator;
        $this->io = $io;
    }

    /**
     * @param PackageInterface $package
     */
    public function deploy(PackageInterface $package): void
    {
        if ($package->getType() !== 'magento2-module') {
            return;
        }

        $packageName = $package->getName();
        if (0 !== strpos($packageName,'magento/module-inventory')) {
            return;
        }

        $moduleName = $this->packageNameToModuleName($packageName);
        $this->io->writeError(sprintf(
            '    ...Module %s recognized as part of Magento Multi Source Inventory implementation',
            $moduleName
        ), true);

        $this->configurator->configure($moduleName);
    }

    private function packageNameToModuleName(string $packageName): string
    {
        $nameWithDashes = substr($packageName, strlen('magento/module-'));
        $nameInCamelCase = ucwords($nameWithDashes, '-');
        $nameWithoutDashes = str_replace('-', '', $nameInCamelCase);
        $nameWithVendorPrefix = 'Magento_' . $nameWithoutDashes;
        $packageName = $nameWithVendorPrefix;
        return $packageName;
    }
}
