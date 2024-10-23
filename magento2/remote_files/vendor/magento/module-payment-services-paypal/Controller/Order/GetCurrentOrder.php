<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\PaymentServicesPaypal\Controller\Order;

use Magento\Framework\Controller\ResultFactory;
use Magento\Framework\Controller\ResultInterface;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Checkout\Model\Session as CheckoutSession;
use Magento\PaymentServicesPaypal\Model\OrderService;
use Magento\PaymentServicesBase\Model\HttpException;
use Magento\Framework\Webapi\Exception as WebapiException;
use Magento\Framework\Webapi\Rest\Response as WebapiResponse;

class GetCurrentOrder implements HttpGetActionInterface
{
    /**
     * @param CheckoutSession $checkoutSession
     * @param OrderService $orderService
     * @param ResultFactory $resultFactory
     */
    public function __construct(
        private CheckoutSession $checkoutSession,
        private OrderService $orderService,
        private ResultFactory $resultFactory
    ) {
    }

    /**
     * Gets Order details from SaaS based on order id inside current quote object
     *
     * @return ResultInterface
     */
    public function execute() : ResultInterface
    {
        $result = $this->resultFactory->create(ResultFactory::TYPE_JSON);

        try {
            $quote = $this->checkoutSession->getQuote();
            $paypalOrderId = $quote->getPayment()->getAdditionalInformation('paypal_order_id');

            if (!$paypalOrderId) {
                $result->setHttpResponseCode(WebapiException::HTTP_NOT_FOUND);
                return $result;
            }

            $response = $this->orderService->get($paypalOrderId);
            $result->setHttpResponseCode(WebapiResponse::HTTP_OK)
                ->setData(['response' => $response]);
        } catch (HttpException $e) {
            $result->setHttpResponseCode(WebapiException::HTTP_INTERNAL_ERROR);
        }

        return $result;
    }
}
