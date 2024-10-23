<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\PaymentServicesPaypal\Model;

use Magento\Framework\App\Request\Http;
use Magento\PaymentServicesBase\Model\ServiceClientInterface;
use Magento\Vault\Api\Data\PaymentTokenInterface;
use Magento\Vault\Api\PaymentTokenRepositoryInterface;

class VaultService
{
    /**
     * @var Config
     */
    private $config;

    /**
     * @var ServiceClientInterface
     */
    private $httpClient;

    /**
     * @var PaymentTokenRepositoryInterface
     */
    private $tokenRepository;

    /**
     * @param Config $config
     * @param ServiceClientInterface $httpClient
     * @param PaymentTokenRepositoryInterface $tokenRepository
     */
    public function __construct(
        Config $config,
        ServiceClientInterface $httpClient,
        PaymentTokenRepositoryInterface $tokenRepository
    ) {
        $this->config = $config;
        $this->httpClient = $httpClient;
        $this->tokenRepository = $tokenRepository;
    }

    /**
     * Call checkout service to delete vaulted card
     *
     * @param PaymentTokenInterface $paymentToken
     * @param int $customerId
     * @return array
     */
    public function deleteVaultedCard(PaymentTokenInterface $paymentToken, int $customerId): array
    {
        $tokenId = $paymentToken->getGatewayToken();

        $uri = '/'
            . $this->config->getMerchantId()
            . '/vault/card';

        return $this->httpClient->request(
            [
                'x-token-id' => $tokenId,
                'x-commerce-customer-id' => $customerId
            ],
            $uri,
            Http::METHOD_DELETE
        );
    }

    /**
     * Mark payment token as invisible in Commerce DB
     *
     * @param PaymentTokenInterface $paymentToken
     * @return void
     */
    public function deleteVaultedCardFromCommerce(PaymentTokenInterface $paymentToken)
    {
        $this->tokenRepository->delete($paymentToken);
    }
}
