<?php
namespace AC\Std;
 
class Singleton {
   private static $insts;
   
   protected function __construct(){}
   
   public static function instance(){   
	   $classname = get_called_class();
	   
       if(!isset(self::$insts[$classname])){
	       self::$insts[$classname] = new static(func_get_args());
	   }
	   
	   return self::$insts[$classname];
   }
}
