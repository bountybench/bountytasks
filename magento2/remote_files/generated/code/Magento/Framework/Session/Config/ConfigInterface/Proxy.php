<?php
namespace Magento\Framework\Session\Config\ConfigInterface;

/**
 * Proxy class for @see \Magento\Framework\Session\Config\ConfigInterface
 */
class Proxy implements \Magento\Framework\Session\Config\ConfigInterface, \Magento\Framework\ObjectManager\NoninterceptableInterface
{
    /**
     * Object Manager instance
     *
     * @var \Magento\Framework\ObjectManagerInterface
     */
    protected $_objectManager = null;

    /**
     * Proxied instance name
     *
     * @var string
     */
    protected $_instanceName = null;

    /**
     * Proxied instance
     *
     * @var \Magento\Framework\Session\Config\ConfigInterface
     */
    protected $_subject = null;

    /**
     * Instance shareability flag
     *
     * @var bool
     */
    protected $_isShared = null;

    /**
     * Proxy constructor
     *
     * @param \Magento\Framework\ObjectManagerInterface $objectManager
     * @param string $instanceName
     * @param bool $shared
     */
    public function __construct(\Magento\Framework\ObjectManagerInterface $objectManager, $instanceName = '\\Magento\\Framework\\Session\\Config\\ConfigInterface', $shared = true)
    {
        $this->_objectManager = $objectManager;
        $this->_instanceName = $instanceName;
        $this->_isShared = $shared;
    }

    /**
     * @return array
     */
    public function __sleep()
    {
        return ['_subject', '_isShared', '_instanceName'];
    }

    /**
     * Retrieve ObjectManager from global scope
     */
    public function __wakeup()
    {
        $this->_objectManager = \Magento\Framework\App\ObjectManager::getInstance();
    }

    /**
     * Clone proxied instance
     */
    public function __clone()
    {
        if ($this->_subject) {
            $this->_subject = clone $this->_getSubject();
        }
    }

    /**
     * Debug proxied instance
     */
    public function __debugInfo()
    {
        return ['i' => $this->_subject];
    }

    /**
     * Get proxied instance
     *
     * @return \Magento\Framework\Session\Config\ConfigInterface
     */
    protected function _getSubject()
    {
        if (!$this->_subject) {
            $this->_subject = true === $this->_isShared
                ? $this->_objectManager->get($this->_instanceName)
                : $this->_objectManager->create($this->_instanceName);
        }
        return $this->_subject;
    }

    /**
     * {@inheritdoc}
     */
    public function setOptions($options)
    {
        return $this->_getSubject()->setOptions($options);
    }

    /**
     * {@inheritdoc}
     */
    public function getOptions()
    {
        return $this->_getSubject()->getOptions();
    }

    /**
     * {@inheritdoc}
     */
    public function setOption($option, $value)
    {
        return $this->_getSubject()->setOption($option, $value);
    }

    /**
     * {@inheritdoc}
     */
    public function getOption($option)
    {
        return $this->_getSubject()->getOption($option);
    }

    /**
     * {@inheritdoc}
     */
    public function toArray()
    {
        return $this->_getSubject()->toArray();
    }

    /**
     * {@inheritdoc}
     */
    public function setName($name)
    {
        return $this->_getSubject()->setName($name);
    }

    /**
     * {@inheritdoc}
     */
    public function getName()
    {
        return $this->_getSubject()->getName();
    }

    /**
     * {@inheritdoc}
     */
    public function setSavePath($savePath)
    {
        return $this->_getSubject()->setSavePath($savePath);
    }

    /**
     * {@inheritdoc}
     */
    public function getSavePath()
    {
        return $this->_getSubject()->getSavePath();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookieLifetime($cookieLifetime)
    {
        return $this->_getSubject()->setCookieLifetime($cookieLifetime);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookieLifetime()
    {
        return $this->_getSubject()->getCookieLifetime();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookiePath($cookiePath)
    {
        return $this->_getSubject()->setCookiePath($cookiePath);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookiePath()
    {
        return $this->_getSubject()->getCookiePath();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookieDomain($cookieDomain)
    {
        return $this->_getSubject()->setCookieDomain($cookieDomain);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookieDomain()
    {
        return $this->_getSubject()->getCookieDomain();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookieSecure($cookieSecure)
    {
        return $this->_getSubject()->setCookieSecure($cookieSecure);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookieSecure()
    {
        return $this->_getSubject()->getCookieSecure();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookieHttpOnly($cookieHttpOnly)
    {
        return $this->_getSubject()->setCookieHttpOnly($cookieHttpOnly);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookieHttpOnly()
    {
        return $this->_getSubject()->getCookieHttpOnly();
    }

    /**
     * {@inheritdoc}
     */
    public function setUseCookies($useCookies)
    {
        return $this->_getSubject()->setUseCookies($useCookies);
    }

    /**
     * {@inheritdoc}
     */
    public function getUseCookies()
    {
        return $this->_getSubject()->getUseCookies();
    }

    /**
     * {@inheritdoc}
     */
    public function setCookieSameSite(string $cookieSameSite) : \Magento\Framework\Session\Config\ConfigInterface
    {
        return $this->_getSubject()->setCookieSameSite($cookieSameSite);
    }

    /**
     * {@inheritdoc}
     */
    public function getCookieSameSite() : string
    {
        return $this->_getSubject()->getCookieSameSite();
    }
}
