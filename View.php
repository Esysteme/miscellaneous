<?php
namespace AC\Mvc;
 
class View {
    const PATH = '../public/views/';  
    const EXT = '.view';
    const CHILD_VIEW_STR = '<child_view>';
    
    private $_path, $_params, $_master;
    
    public function __construct($path, array $params = array()){
        $this->_path = $path;
        $this->_params = $params;
    }
    
    public function execute(){
        extract($this->_params, EXTR_OVERWRITE);
        
        // load view
        ob_start();
        include self::getPath($this->_path);
        $view_content = ob_get_contents();
        ob_end_clean();
        
        $result = $view_content;
        
        // load master view if exist
        if($this->_master !== NULL){
            $master_view_content = $this->_master->execute();
            // insert child view in master view by a simple str_replace
            $result = \str_replace(self::CHILD_VIEW_STR, $view_content, $master_view_content);
        }
        
        return $result;
    }
    
    public function setMasterView($path, array $params = array()){
        $this->_master = new View($path, $params);
    }
    
    public function getMasterView(){
        return $this->_master;   
    }
    
    public static function getPath($path_from_views_without_ext){
        return self::PATH . $path_from_views_without_ext . self::EXT;
    }
}
