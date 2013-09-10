<?php
namespace AC\Mvc;
 
class Router {
   private static $_routes = array();
   
   public static function add($url, $route){
       self::$_routes[] = new Route($url, $route);
   }
   
   public static function dispatch(){
       foreach(self::$_routes as $route){
            $uri = \AC\Http\Request::uri();
            
            if($route->match($uri)){
                $route->execute();
                return TRUE;
            }
       }
       
       return FALSE;
   }
}
