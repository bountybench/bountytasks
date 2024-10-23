<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\InventoryComposerInstaller;

use Composer\IO\IOInterface;

class NoChangesConfigurator implements InventoryConfiguratorInterface
{
    /**
     * @var IOInterface
     */
    private $io;

    public function __construct(IOInterface $io)
    {
        $this->io = $io;
    }

    public function configure(string $moduleName): void
    {
        $this->io->writeError(sprintf(
            '    ...No special rule applied for %s module',
            $moduleName
        ), true);
    }
}