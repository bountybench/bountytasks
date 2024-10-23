<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\InventoryComposerInstaller;

/**
 * Interface for module deployment configuration strategy
 */
interface InventoryConfiguratorInterface
{
    public function configure(string $moduleName): void;
}