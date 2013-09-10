<?php
namespace AC\Mvc;
 
class Route {
    private $_uri, $_route;
    
    public function __construct($uri, $route){
        if(!is_string($uri))
            throw new \AC\Std\WrongArgumentException('$url must be a string');
        
        if(!is_callable($route))
            throw new \AC\Std\WrongArgumentException('$route must be callable');
        
        $this->_uri = $uri;
        $this->_route = $route;
    }
    
    public function match($uri){
        return $this->_uri === $uri;
    }
    
    public function execute(){
        $controller = call_user_func($this->_route);
    
        if($controller !== NULL && $controller instanceof Controller){            
            $response_body = $controller->execute($this->_uri);    
        }elseif(is_string($controller)){
            $response_body = $controller;
        }
 
        if(!empty($response_body)){
            \AC\Http\Response::setBody($response_body);
        }
    }
}
