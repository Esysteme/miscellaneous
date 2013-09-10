<?php
namespace AC\Db;
 
class Table { // todo extends ArrayAccess to get $_values
   
    private $_name, $_fields, $_values, $_relations;
   
	private static $_table = array();
   
    public function __construct($name, array $fields, array $values = array(), array $relations = array()){
        $this->_name = $name;
        $this->_fields = $fields;
        $this->_values = $values;
		$this->_values = $relations;
    }
    
    public function __call($name, $arguments){
        $prefix = substr($name, 0, 3);
        $suffix = substr($name, 3);
        $field_name =  strtolower(preg_replace('/(?<=\\w)(?=[A-Z])/',"_$1", $suffix));
        
        if(isset($this->_fields[$field_name])){
			// it's a field so set or get
            if($prefix === 'set'){
                $this->_values[$field_name] = $arguments[0]; 
            }elseif($prefix === 'get'){
                if(isset($this->_values[$field_name])){
					return $this->_values[$field_name];
				}else{
					return NULL;
				}
            }
        }else{
		    // TODO : it may concern a relation to another model
			// aka $model->getUser()->getMatchs()...
            throw new \AC\Std\MethodNotFoundException(get_called_class(), $name);
        }
    }
    
    public function getByPk($pk){
        return $this->get($this->_fields['pk'] . '=' . intval($pk));
    }
    
    public function deleteByPk($pk){
        return $this->delete($this->_fields['pk'] . '=' . intval($pk));
    }
    
    public function get($condition = '', $multiple = FALSE){
		$q = Db::instance()->select('*')->from($this->_name)->where($condition)->query();
        $c = get_called_class();
		$res = array();
		
		while($row = $q->fetch()){
			$res[] = new $c($this->_name, $this->_fields, $row);
			if(!$multiple){
				break;
			}
		}        
        
        return $multiple ? $res : (count($res) > 0 ? $res[0] : NULL);
    }
	
	public function getAll(){
		return $this->get('', TRUE);
	}
        
    public function update(\AC\Db\Table $table){
        $db = Db::instance()->update()->from($this->_name);
        $fields = $table->getFields(); 
        $values = $table->getValues();
        
        foreach($fields as $field){
            $db->set($field, $values[$field]);
        }
        
        $db->where($fields['pk'] . '=' . intval($values[$fields['pk']]));
        
        $db->query();
    }
    
    public function delete($condition = ''){
        return Db::instance()->delete()->from($this->_name)->where($condition)->query();
    }
	
	public function insert(array $values = array()){
		$values = empty($values) ? $this->_values : $values;
		return Db::instance()->insert()->into($this->_name)->values($values)->query();
	}
    
    public function getValues(){
        return $this->_values;
    }
	
	public function setValues(array $values){
		$this->_values = $values;
	}
    
    public function getFields(){
        return $this->_fields;
    }
	
	public static function getInstance($renew = FALSE){
		if($renew || !isset($this->_tables[$this->_name])){
			$this->_tables[$this->_name] = new self;
		}
		
		return $this->_tables[$this->_name];
	}
}
