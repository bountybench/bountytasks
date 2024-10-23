# Property accessor and mutator functions.

Property accessors and mutators are commonly referred to as "getter" and "setter" functions. This library uses [PHP's Magic Methods][magic-methods] to easily hook up getter and setter functions that are exposed externally as normal properties, via the `MagicProp` trait.

Why? This kind of functionality can certainly be seen as a hack, but sometimes hacks are necessary. Specifically PHP.Gt is implementing [the DOM standard in PHP][dom] which requires certain properties to have "live" or "readonly" functionality, which is only possible using magic __get and __set functions. This library simply holds the reusable behaviour for other repositories that require it.

***

<a href="https://github.com/PhpGt/PropFunc/actions" target="_blank">
	<img src="https://badge.status.php.gt/propfunc-build.svg" alt="Build status" />
</a>
<a href="https://scrutinizer-ci.com/g/PhpGt/PropFunc" target="_blank">
	<img src="https://badge.status.php.gt/propfunc-quality.svg" alt="Code quality" />
</a>
<a href="https://scrutinizer-ci.com/g/PhpGt/PropFunc" target="_blank">
	<img src="https://badge.status.php.gt/propfunc-coverage.svg" alt="Code coverage" />
</a>
<a href="https://packagist.org/packages/PhpGt/PropFunc" target="_blank">
	<img src="https://badge.status.php.gt/propfunc-version.svg" alt="Current version" />
</a>
<a href="http://www.php.gt/propfunc" target="_blank">
	<img src="https://badge.status.php.gt/propfunc-docs.svg" alt="PHP.Gt/PropFunc documentation" />
</a>

Example usage: Read-only properties that are calculated upon access
-------------------------------------------------------------------

See the class `Day` below, which represents a day in time:

```php
use Gt\PropFunc\MagicProp;

/**
 * @property-read bool $future True if the day is in the future
 * @property-read int $daysApart Days between now and this day
 */
class Day {
	use MagicProp;
	
	public function __construct(
		private DateTimeInterface $dateTime
	) {}
	
// Expose the "dateTime" private property with read-only access:
	private function __prop_get_dateTime():DateTimeInterface {
		return $this->dateTime;
	}
	
// Expose the "future" calculated property with read-only access:
	private function __prop_get_future():bool {
		$now = new DateTime();
		return $now < $this->dateTime;
	}
	
// Expose the "daysApart" calculated property with read-only access:
	private function __prop_get_daysApart():int {
		$now = new DateTime();
		$diff = $now->diff($this->dateTime);
		return $diff->days;
	}
}
```

See the code below which uses the `Day` class. It can access the properties, but not mutate them.

```php
$day = new Day($dateTime);
echo "Day is $day->diff days in the ";
echo $day->future ? "future" : "past";
echo PHP_EOL;
$day->diff = 10;
echo "Exception thrown on line above!";
```

Usages
------

+ Read only properties - as with the above example, properties can be made read-only. This feature is [coming to the PHP language][write-once-property-rfc], but without the ability to define the accessor logic.
+ Live properties - if a property's value is required to update depending on certain conditions, a getter function is required.
+ Property validation - if a property's value can't simply be validated by its type alone, the setter function can be used to ensure the value meets validation criteria.

[magic-methods]: https://www.php.net/manual/en/language.oop5.magic.php
[dom]: https://www.php.gt/dom
[write-once-property-rfc]: https://wiki.php.net/rfc/write_once_properties
