<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\PaymentServicesPaypal\Observer;

use Magento\Framework\Event\ObserverInterface;
use Magento\Framework\Event\Observer as EventObserver;
use Magento\Framework\Event;
use Magento\PaymentServicesPaypal\Block\SmartButtons;
use Magento\PaymentServicesPaypal\Block\Message;
use Magento\Checkout\Block\QuoteShortcutButtons;

class AddCheckoutComponents implements ObserverInterface
{
    /**
     * @var array
     */
    private $blocks;

    /**
     * @param array $blocks
     */
    public function __construct(array $blocks = [])
    {
        $this->blocks = $blocks;
    }

    /**
     * @ingeritdoc
     */
    public function execute(EventObserver $observer)
    {
        /** @var QuoteShortcutButtons $shortcutButtons */
        $shortcutButtons = $observer->getEvent()->getContainer();
        $smartButtons = $shortcutButtons->getLayout()->createBlock(
            $this->blocks[$this->getPageType($observer->getEvent())],
            '',
            [
                'pageType' => $this->getPageType($observer->getEvent()),
            ]
        );
        $shortcutButtons->addShortcut($smartButtons);
        $message = $shortcutButtons->getLayout()->createBlock(
            Message::class,
            '',
            [
                'pageType' => $this->getPageType($observer->getEvent()),
            ]
        );
        $shortcutButtons->addShortcut($message);
    }

    /**
     * @param Event $event
     * @return string
     */
    private function getPageType($event) : string
    {
        if ($event->getIsCatalogProduct()) {
            return 'product';
        }
        if ($event->getIsShoppingCart()) {
            return 'cart';
        }
        return 'minicart';
    }
}
