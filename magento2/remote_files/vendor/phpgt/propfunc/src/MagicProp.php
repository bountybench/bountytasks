<?php
namespace Gt\PropFunc;

use ReflectionProperty;

trait MagicProp {
	/** @var array<string, mixed> */
	protected array $__prop = [];

	/** @return mixed */
	public function __get(string $name) {
		$method = $this->getMagicPropMethod($name);
		if(!method_exists($this, $method)) {
			throw new PropertyDoesNotExistException($name);
		}
		return call_user_func([$this, $method]);
	}

	/** @param mixed $value */
	public function __set(string $name, $value):void {
		if(property_exists($this, $name)) {
			$prop = new ReflectionProperty($this, $name);
			if($prop->isPublic()) {
				$this->$name = $value;
				return;
			}
		}

		$setMethod = $this->getMagicPropMethod($name, "set");
		if(method_exists($this, $setMethod)) {
			call_user_func([$this, $setMethod], $value);
			return;
		}

		$getMethod = $this->getMagicPropMethod($name);
		if(method_exists($this, $getMethod)) {
			throw new PropertyReadOnlyException($name);
		}
		else {
			throw new PropertyDoesNotExistException($name);
		}
	}

	public function __isset(string $name):bool {
		if(property_exists($this, $name)) {
			return isset($this->$name);
		}

		$method = $this->getMagicPropMethod($name);
		return method_exists($this, $method);
	}

	public function __unset(string $name):void {
		$setMethod = $this->getMagicPropMethod($name, "set");
		if(!method_exists($this, $setMethod)) {
			throw new PropertyReadOnlyException($name);
		}

		unset($this->$name);
	}

	private function getMagicPropMethod(
		string $name,
		string $action = "get"
	):string {
		return "__prop_{$action}_{$name}";
	}
}
