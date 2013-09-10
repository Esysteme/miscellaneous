<?php
namespace AC\Mvc;
 
class Controller {
    private $_action = NULL;    
    const METHOD_SUFFIX = 'Action';  
    
    public function __construct($action = NULL, View $view = null){
        $this->_action = $action;
        $this->_view = $view;
    }   
    
    public function execute($url){
        $method = 'index' . self::METHOD_SUFFIX;
        $class_name = join('', array_slice(explode('\\', get_class($this)), -1));
        
        if($this->_action !== NULL){
            $method = \lcfirst() . self::METHOD_SUFFIX;
            
            if(!\method_exists($this, $method)){
                throw new \AC\Std\MethodNotFoundException($class_name, $method);
            }
        }
        
        $view_params = $this->$method();
        $view_path = strtolower($class_name . '/' . str_replace(self::METHOD_SUFFIX, '', $method));
        
        if($this->_view === NULL){
            $this->_view = new View($view_path, $view_params);
        }
        
        return $this->_view->execute();        
    }
    
    public function indexAction(){
        return array(
            'param_to_be_used_in_a_view' => 'Hello world'
        );
    }
}
