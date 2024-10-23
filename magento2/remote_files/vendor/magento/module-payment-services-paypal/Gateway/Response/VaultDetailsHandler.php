<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace Magento\PaymentServicesPaypal\Gateway\Response;

use Exception;
use DateInterval;
use DateTime;
use DateTimeZone;
use Magento\Payment\Gateway\Data\PaymentDataObjectInterface;
use Magento\Payment\Gateway\Response\HandlerInterface;
use Magento\Vault\Api\Data\PaymentTokenFactoryInterface;
use Magento\Framework\Serialize\Serializer\Json;
use Magento\Vault\Api\Data\PaymentTokenInterface;
use Magento\Payment\Model\InfoInterface;
use Magento\Sales\Api\Data\OrderPaymentExtensionInterfaceFactory;
use Magento\Sales\Api\Data\OrderPaymentExtensionInterface;
use Psr\Log\LoggerInterface;

/**
 * @SuppressWarnings(PHPMD.CouplingBetweenObjects)
 */
class VaultDetailsHandler implements HandlerInterface
{
    /**
     * @var PaymentTokenFactoryInterface
     */
    private PaymentTokenFactoryInterface $paymentTokenFactory;

    /**
     * @var OrderPaymentExtensionInterfaceFactory
     */
    private OrderPaymentExtensionInterfaceFactory $paymentExtensionFactory;

    /**
     * @var Json
     */
    private Json $serializer;

    /**
     * @var LoggerInterface
     */
    private $logger;

    /**
     * @param PaymentTokenFactoryInterface $paymentTokenFactory
     * @param OrderPaymentExtensionInterfaceFactory $paymentExtensionFactory
     * @param Json $serializer
     * @param LoggerInterface $logger
     */
    public function __construct(
        PaymentTokenFactoryInterface $paymentTokenFactory,
        OrderPaymentExtensionInterfaceFactory $paymentExtensionFactory,
        Json $serializer,
        LoggerInterface $logger
    ) {
        $this->paymentTokenFactory = $paymentTokenFactory;
        $this->paymentExtensionFactory = $paymentExtensionFactory;
        $this->serializer = $serializer;
        $this->logger = $logger;
    }

    /**
     * Handles vault save
     *
     * @param array $handlingSubject
     * @param array $response
     * @return void
     * @throws Exception
     */
    public function handle(array $handlingSubject, array $response)
    {
        if (!isset($handlingSubject['payment'])
            || !$handlingSubject['payment'] instanceof PaymentDataObjectInterface
        ) {
            throw new \InvalidArgumentException('Payment data object should be provided');
        }

        if (isset($response['mp-transaction']['vault'])) {
            $vault = $response['mp-transaction']['vault'];
            $paymentDO = $handlingSubject['payment'];
            $payment = $paymentDO->getPayment();
            try {
                $paymentToken = $this->createPaymentToken($vault);

                $extensionAttributes = $this->getExtensionAttributes($payment);
                $extensionAttributes->setVaultPaymentToken($paymentToken);
            } catch (Exception $e) {
                $this->logger->error($e->getMessage());
            }
        }
    }
    /**
     * Creates vault payment token.
     *
     * @param array $vault
     * @return PaymentTokenInterface
     * @throws Exception
     */
    private function createPaymentToken(array $vault): PaymentTokenInterface
    {
        $vaultId = $vault['vault-token-id'];
        $vaultDetails = $vault['provider-vault-details'];
        $paymentToken = $this->paymentTokenFactory->create(PaymentTokenFactoryInterface::TOKEN_TYPE_CREDIT_CARD);
        $paymentToken->setGatewayToken($vaultId);
        $exp = explode('-', $vaultDetails['expiry']);
        $expYear = $exp[0];
        $expMonth = $exp[1];
        $paymentToken->setExpiresAt($this->getExpiryDate($expYear, $expMonth));
        $paymentToken->setTokenDetails($this->convertDetailsToJSON([
            'type' => $vaultDetails['type'],
            'brand' => $vaultDetails['brand'],
            'maskedCC' => $vaultDetails['last_digits'],
            'expirationDate' => $expMonth . '/' . $expYear
        ]));

        return $paymentToken;
    }

    /**
     * Convert payment token details to JSON
     *
     * @param array $details
     * @return string
     */
    private function convertDetailsToJSON(array $details): string
    {
        $json = $this->serializer->serialize($details);
        return $json ?: '{}';
    }

    /**
     * Generates CC expiration date by year and month provided in payment.
     *
     * @param string $expYear
     * @param string $expMonth
     * @return string
     * @throws Exception
     */
    private function getExpiryDate(string $expYear, string $expMonth): string
    {
        $expDate = new DateTime(
            $expYear
            . '-'
            . $expMonth
            . '-'
            . '01'
            . ' '
            . '00:00:00',
            new DateTimeZone('UTC')
        );
        $expDate->add(new DateInterval('P1M'));
        return $expDate->format('Y-m-d 00:00:00');
    }

    /**
     * Get payment extension attributes
     *
     * @param InfoInterface $payment
     * @return OrderPaymentExtensionInterface
     */
    private function getExtensionAttributes(InfoInterface $payment): OrderPaymentExtensionInterface
    {
        $extensionAttributes = $payment->getExtensionAttributes();
        if (null === $extensionAttributes) {
            $extensionAttributes = $this->paymentExtensionFactory->create();
            $payment->setExtensionAttributes($extensionAttributes);
        }
        return $extensionAttributes;
    }
}
