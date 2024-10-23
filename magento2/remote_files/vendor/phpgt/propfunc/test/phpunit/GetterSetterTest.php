<?php
namespace Gt\PropFunc\Test;

use Gt\PropFunc\PropertyDoesNotExistException;
use Gt\PropFunc\PropertyReadOnlyException;
use Gt\PropFunc\Test\Helper\PropertyAlreadyWrittenException;
use PHPUnit\Framework\TestCase;
use Gt\PropFunc\Test\Helper\ExampleGetterSetter;
use StdClass;

class GetterSetterTest extends TestCase {
	public function testIsset():void {
		$sut = new ExampleGetterSetter();
		self::assertTrue(isset($sut->constructedAt));
		self::assertFalse(isset($sut->name));
		self::assertFalse(isset($sut->thisPropertyDoesNotExist));
	}

	public function testPropertyExists():void {
		$sut = new ExampleGetterSetter();
		self::assertTrue(property_exists($sut, "name"));
	}

	public function testSetName():void {
		$sut = new ExampleGetterSetter();
		$sut->name = "Test";
		self::assertEquals("Test", $sut->name);
	}

	public function testUnsetSetName():void {
		$sut = new ExampleGetterSetter();
		$sut->name = "Test";
		self::assertTrue(isset($sut->name));
		unset($sut->name);
		self::assertFalse(isset($sut->name));
		$sut->name = "Test";
		self::assertTrue(isset($sut->name));
	}

	public function testUnsetReadOnly():void {
		$sut = new ExampleGetterSetter();
		self::expectException(PropertyReadOnlyException::class);
		unset($sut->constructedAt);
	}

	public function testUnsetMagic():void {
		$sut = new ExampleGetterSetter();
		$sut->age = 123;
		self::assertEquals(123, $sut->age);
		unset($sut->age);
		self::assertEquals(time() - $sut->constructedAt, $sut->age);
	}

	public function testGetUcName():void {
		$sut = new ExampleGetterSetter();
		$sut->name = "test";
		self::assertEquals("TEST", $sut->ucName);
	}

	public function testGetNonExistentProperty():void {
		$sut = new ExampleGetterSetter();
		self::expectException(PropertyDoesNotExistException::class);
		$sut->nothing;
	}

	public function testSetNonExistentProperty():void {
		$sut = new ExampleGetterSetter();
		self::expectException(PropertyDoesNotExistException::class);
		$sut->nothing = "something";
	}

	public function testSetReadOnlyProperty():void {
		$sut = new ExampleGetterSetter();
		self::expectException(PropertyReadOnlyException::class);
		/** @var StdClass $sut Suppress the IDE-error on line below! */
		$sut->ucName = "SOMETHING";
	}

	public function testExistingPropertyOverridden():void {
		$sut = new ExampleGetterSetter();
		self::assertIsInt($sut->id);
	}

	public function testExistingPropertyReadOnly():void {
		$sut = new ExampleGetterSetter();
		self::expectException(PropertyReadOnlyException::class);
		$propertyName = "id";
		$sut->$propertyName = 123;
	}

	public function testInternalPropertyValue():void {
		$sut = new ExampleGetterSetter();
		$sut->internalProperty = "example";
		self::assertEquals("example", $sut->internalProperty);
	}

	public function testInternalReadOnlyProperty():Void {
		$sut = new ExampleGetterSetter();
		self::assertEquals("this is read only", $sut->internalReadOnly);
		self::expectException(PropertyReadOnlyException::class);
		$sut->internalReadOnly = "changed";
	}

	public function testWriteOnce():void {
		$sut = new ExampleGetterSetter();
		$sut->writeMeOnce = "written once";
		self::assertEquals("written once", $sut->writeMeOnce);

		$exception = null;
		try {
			$sut->writeMeOnce = "written twice";
		}
		catch(PropertyAlreadyWrittenException $exception) {}

		self::assertNotNull($exception);
		self::assertEquals("written once", $sut->writeMeOnce);
	}

	public function testInternalWriteOnce():void {
		$sut = new ExampleGetterSetter();
		$sut->internalWriteMeOnce = "written once";
		self::assertEquals("written once", $sut->internalWriteMeOnce);

		$exception = null;
		try {
			$sut->internalWriteMeOnce = "written twice";
		}
		catch(PropertyAlreadyWrittenException $exception) {}

		self::assertNotNull($exception);
		self::assertEquals("written once", $sut->internalWriteMeOnce);
	}
}
