<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\InventoryComposerInstaller;

use Composer\IO\IOInterface;
use Magento\Framework\App\DeploymentConfig;
use Magento\Framework\Config\File\ConfigFilePool;

class DisabledInventoryConfiguration implements InventoryConfiguratorInterface
{
    /**
     * @var DeploymentConfig
     */
    private $deploymentConfig;

    /**
     * @var DeploymentConfig\Writer
     */
    private $deploymentConfigWriter;

    /**
     * @var IOInterface
     */
    private $io;

    public function __construct(
        DeploymentConfig $deploymentConfig,
        DeploymentConfig\Writer $deploymentConfigWriter,
        IOInterface $io
    ) {
        $this->deploymentConfig = $deploymentConfig;
        $this->deploymentConfigWriter = $deploymentConfigWriter;
        $this->io = $io;
    }

    public function configure(string $moduleName): void
    {
        if ($this->isModuleAlreadyConfigured($moduleName)) {
            $this->doNotChangeConfiguredValue($moduleName);
            return;
        }

        $this->disableModule($moduleName);
    }

    private function isModuleAlreadyConfigured(string $moduleName): bool
    {
        $configValue = $this->getModuleConfigurationValue($moduleName);
        return null !== $configValue;
    }

    private function doNotChangeConfiguredValue($moduleName): void
    {
        $configValue = $this->getModuleConfigurationValue($moduleName);
        if (null === $configValue) {
            $moduleStatus = 'undefined';
        } elseif ($configValue) {
            $moduleStatus = 'enabled';
        } else {
            $moduleStatus = 'disabled';
        }

        $this->io->writeError(sprintf(
            '    ...Keep %s module %s as in current configuration',
            $moduleName,
            $moduleStatus
        ), true);
    }

    private function disableModule($moduleName): void
    {
        $this->io->writeError(sprintf(
            '    ...Disabling %s module for backward compatibility',
            $moduleName
        ), true);

        $this->deploymentConfigWriter->saveConfig([
            ConfigFilePool::APP_CONFIG => [
                'modules' => [
                    $moduleName => 0,
                ]
            ]
        ]);
    }

    private function getModuleConfigurationValue(string $moduleName): ?bool
    {
        $configKey = 'modules/' . $moduleName;
        $configValue = $this->deploymentConfig->get($configKey);
        return isset($configValue) ? (bool)$configValue : null;
    }
}