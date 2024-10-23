<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Test\Unit\Model;

use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use PayPal\BraintreeGraphQl\Model\BraintreeDataProvider;
use PHPUnit\Framework\TestCase;

/**
 * @group paypal-braintree-graphql
 */
class BraintreeDataProviderTest extends TestCase
{
    private const PATH_ADDITIONAL_DATA = 'braintree';

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataReturnsCorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreeDataProvider();

        $this->assertSame($this->getData(), $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataDoesNotReturnIncorrectData(): void
    {
        $input = [self::PATH_ADDITIONAL_DATA => $this->getData()];

        $dataProvider = new BraintreeDataProvider();

        $falseResult = $this->getData();
        unset($falseResult[array_rand($falseResult)]);

        $this->assertNotSame($falseResult, $dataProvider->getData($input));
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeDataProvider::getData()
     */
    public function testGetDataExceptionIfAdditionalDataAreMissing(): void
    {
        $this->expectException(GraphQlInputException::class);

        $dataProvider = new BraintreeDataProvider();

        $dataProvider->getData([]);
    }

    /**
     * @covers \PayPal\BraintreeGraphQl\Model\BraintreeDataProvider::getData()
     *
     * @throws \Magento\Framework\GraphQl\Exception\GraphQlInputException
     */
    public function testGetDataExceptionMessageIfAdditionalDataAreMissing(): void
    {
        $this->expectExceptionMessage('Required parameter "braintree" for "payment_method" is missing.');

        $dataProvider = new BraintreeDataProvider();

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
