<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\InventoryComposerInstaller;

use Composer\Autoload\ClassLoader;
use Composer\Composer;
use Composer\DependencyResolver\Operation\InstallOperation;
use Composer\DependencyResolver\Operation\UpdateOperation;
use Composer\EventDispatcher\EventSubscriberInterface;
use Composer\Installer\PackageEvent;
use Composer\IO\IOInterface;
use Composer\Plugin\PluginInterface;
use Magento\Framework\App\Bootstrap;
use Magento\Framework\App\DeploymentConfig;
use Magento\Framework\Autoload\AutoloaderRegistry;
use Magento\Framework\Autoload\ClassLoaderWrapper;

class Plugin implements PluginInterface, EventSubscriberInterface
{
    /**
     * @var Composer
     */
    private $composer;
    /**
     * @var IOInterface
     */
    private $io;

    /**
     * @var InventoryModuleDeployment
     */
    private $moduleDeployment;

    public function activate(Composer $composer, IOInterface $io)
    {
        $this->composer = $composer;
        $this->io = $io;
    }

    public static function getSubscribedEvents()
    {
        return [
            'pre-install-cmd' => 'initModuleDeployment',
            'pre-update-cmd' => 'initModuleDeployment',
            'post-package-install' => 'onPackageChange',
            'post-package-update' => 'onPackageChange',
        ];
    }

    public function initModuleDeployment(): void
    {
        try {
            if (!defined('BP')) {
                define('BP', getcwd());
            }
            AutoloaderRegistry::registerAutoloader(new ClassLoaderWrapper(new ClassLoader()));

            $configurator = (new InventoryConfiguratorFactory($this->io))->createConfigurator(BP);
        } catch (\Throwable $e) {
            $configurator = new NoChangesConfigurator($this->io);
        }

        $this->moduleDeployment = new InventoryModuleDeployment($configurator, $this->io);
    }

    public function onPackageChange(PackageEvent $event): void
    {
        $operation = $event->getOperation();
        if ($operation instanceof InstallOperation) {
            $package = $operation->getPackage();
        } elseif ($operation instanceof UpdateOperation) {
            $package = $operation->getTargetPackage();
        } else {
            return;
        }

        $this->getModuleDeployment()->deploy($package);
    }

    private function getModuleDeployment(): InventoryModuleDeployment
    {
        if (!isset($this->moduleDeployment)) {
            $this->initModuleDeployment();
        }
        return $this->moduleDeployment;
    }

    /**
     * @inheritdoc
     */
    public function deactivate(Composer $composer, IOInterface $io)
    {
    }

    /**
     * @inheritdoc
     */
    public function uninstall(Composer $composer, IOInterface $io)
    {
    }
}
