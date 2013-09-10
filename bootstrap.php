<?php
 
function __autoload($class) {
    $path = str_replace('AC', '', $class);
    $path = str_replace('\\', '/', $path);
    $path = __DIR__ . '/' . ltrim($path, '/') . '.php';
        
    if(file_exists($path)){
        require $path;    
    }
}
 
use \AC\Mvc\Router as Router,
    \AC\Http\Response as Response,
    \AC\i18n\Culture as Culture;
 
class AC extends \AC\Std\Singleton {
   
   protected function __construct(){
       $this->initDb();
       $this->initRoutes();
       $this->initCulture();
   }
   
   private function initDb(){
       \AC\Db\Db::instance('localhost', 'dbname', 'user', 'pwd');
   }
   
   private function initRoutes(){
       Router::add('', function(){
           return new \AC\Mvc\Controllers\Home();
       });
       
       Router::add('inscription', function(){
           return new \AC\Mvc\Controllers\Register();
       });
   }
   
   private function initCulture(){
       Culture::setCurrent('fr-FR');
   }
   
   public function dispatch(){
       Router::dispatch();
       Response::dispatch();
   }
}
