<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Test\Unit\Model;

use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use PayPal\BraintreeGraphQl\Model\BraintreePayPalDataProvider;
use PHPUnit\Framework\TestCase;

/**
 * @group paypal-braintree-graphql
 * @group paypal-braintree-graphql-paypal
 */
class BraintreePayPalDataProviderTest extends TestCase
{
    private const PATH_ADDITIONAL_DATA = 'braintree_paypal';

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreePayPalDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataReturnsCorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreePayPalDataProvider();

        $this->assertSame($this->getData(), $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreePayPalDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataDoesNotReturnIncorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreePayPalDataProvider();

        $falseResult = $this->getData();
        unset($falseResult[array_rand($falseResult)]);

        $this->assertNotSame($falseResult, $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreePayPalDataProvider::getData()
     */
    public function testGetDataExceptionIfAdditionalDataAreMissing(): void
    {
        $this->expectException(GraphQlInputException::class);

        $dataProvider = new BraintreePayPalDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreePayPalDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataExceptionMessageIfAdditionalDataAreMissing(): void
    {
        $this->expectExceptionMessage('Required parameter "braintree_paypal" for "payment_method" is missing.');

        $dataProvider = new BraintreePayPalDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @return string[]
     */
    private function getData(): array
    {
        return [
            'random_key_1' => 'random_key_1_value',
            'random_key_2' => 'random_key_2_value'
        ];
    }
}
