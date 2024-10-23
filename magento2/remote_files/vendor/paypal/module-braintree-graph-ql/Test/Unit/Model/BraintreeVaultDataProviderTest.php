<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Test\Unit\Model;

use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider;
use PHPUnit\Framework\TestCase;

/**
 * @group paypal-braintree-graphql
 * @group paypal-braintree-graphql-vault
 */
class BraintreeVaultDataProviderTest extends TestCase
{
    private const PATH_ADDITIONAL_DATA = 'braintree_cc_vault';

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataReturnsCorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreeVaultDataProvider();

        $this->assertSame($this->getData(), $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataDoesNotReturnIncorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreeVaultDataProvider();

        $falseResult = $this->getData();
        unset($falseResult[array_rand($falseResult)]);

        $this->assertNotSame($falseResult, $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     */
    public function testGetDataExceptionIfAdditionalDataAreMissing(): void
    {
        $this->expectException(GraphQlInputException::class);

        $dataProvider = new BraintreeVaultDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataExceptionMessageIfAdditionalDataAreMissing(): void
    {
        $this->expectExceptionMessage('Required parameter "braintree_cc_vault" for "payment_method" is missing.');

        $dataProvider = new BraintreeVaultDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     */
    public function testGetDataExceptionIfAdditionalDataPublicHashIsMissing(): void
    {
        $this->expectException(GraphQlInputException::class);

        $dataProvider = new BraintreeVaultDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeVaultDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataExceptionMessageIfAdditionalDataPublicHashIsMissing(): void
    {
        $this->expectExceptionMessage('Required parameter "public_hash" for "braintree_cc_vault" is missing.');

        $dataProvider = new BraintreeVaultDataProvider();

        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];
        unset($input[self::PATH_ADDITIONAL_DATA]['public_hash']);

        $dataProvider->getData($input);
    }

    /**
     * @return string[]
     */
    private function getData(): array
    {
        return [
            'public_hash' => 'public_hash_value',
            'random_key_1' => 'random_key_1_value',
            'random_key_2' => 'random_key_2_value'
        ];
    }
}
