<?php
namespace AC\Db;
 
class Db extends \AC\Std\Singleton{
   
   private $_pdo, $_query_builder, $_last_query_string;
   
   const TYPE_INT = 'int';
   const TYPE_STRING = 'string';
   const TYPE_DATE = 'date';
   const TYPE_BIT = 'bit';
   const TYPE_FLOAT = 'float';
   
   protected function __construct($args = array()){
        if(count($args) < 4){
            throw new \App\Std\WrongArgumentException('array passed to Db::instance must contains, in order, host, dbname, user, pwd at least. port is optional.');
        }
        
        $host = $args[0];
        $dbname = $args[1];
        $user = $args[2];
        $pwd = $args[3];
        $port = NULL;
    
        $connection_string = \sprintf('pgsql:host=%s;dbname=%s;user=%s;password=%s',
            $host,
            $dbname,
            $user,
            $pwd
        );
        
        if($port !== NULL){
            $connection_string .= \sprinf(';port=%d', $port);
        }
    
        $this->_pdo = new \PDO($connection_string);
   }
   
   public function query($query_string = ''){        
        if(empty($query_string)){
            if(!empty($this->_query_builder)){
                $query_string = $this->buildQuery();                
            } else{
                throw new \AC\Std\WrongArgumentException('no query string provided, you must either build a query or pass a value in the $query_string parameter');
            } 
        }
        
        $this->_last_query_string = $query_string;
        
        $sth = $this->_pdo->prepare($query_string);
        $sth->execute();
        
        return $sth;
   }
   
   public function fetch($sth){
        return $sth->fetch(\PDO::FETCH_ASSOC);
   }
   
   public function getLastQueryString(){
        return $this->_last_query_string; 
   }
   
   public function buildQuery(){       
        if(!empty($this->_query_builder['select'])){
            $q = 'SELECT ' . $this->_query_builder['select'];
            $q .= ' FROM ' . $this->_query_builder['from'];            
		} elseif(!empty($this->_query_builder['insert'])){
			$q = 'INSERT INTO ' . $this->_query_builder['into'] . ' VALUES(';
			
			for($i = 0, $len = count($this->_query_builder['values']); $i < $len; $i++){
                $q .= '"' . $this->_query_builder['values'][$i] . '",';
            }
			
			if($len > 0){
				$q = substr($q, 0, -1);
			}
			
			$q .= ')';
        }elseif(!empty($this->_query_builder['delete'])){
            $q = 'DELETE FROM ' . $this->_query_builder['from'];
        }elseif(!empty($this->_query_builder['update'])){
            $q = 'UPDATE ' . $this->_query_builder['from'];
            
            for($i = 0, $len = count($this->_query_builder['set']); $i < $len; $i++){
                $q .= ' SET ' . $this->_query_builder['set'][$i][0] . ' = "' . $this->_query_builder['set'][$i][1] . '",';
            }
            
            if($len > 0){
                $q = substr($q, 0, -1);    
            }
        }else{
            return;
        }
        
        if(!empty($this->_query_builder['join'])){
            for($i = 0, $len = count($this->_query_builder['join']); $i < $len; $i++){
                $q .= ' JOIN ' . $this->_query_builder['join'][$i] . ' ON ' . $this->_query_builder['join_condition'][$i];
            }
        }
        
        if(!empty($this->_query_builder['where'])){
            for($i = 0, $len = count($this->_query_builder['where']); $i < $len; $i++){
                $where = $this->_query_builder['where'][$i];
                $kw = ($i === 0) ? ' WHERE ' : $where[1];
                $q .= $kw . $where[0];
            }
        }
        
        if(!empty($this->_query_builder['group_by'])){
            $q .= ' GROUP BY ' . $this->_query_builder['group_by'];
        }
        
        if(!empty($this->_query_builder['limit'])){
            $q .= ' LIMIT ' . $this->_query_builder['limit'];
        }
        
        if(!empty($this->_query_builder['order_by'])){
            $q .= ' ORDER BY ' . $this->_query_builder['order_by'][0] . ', ' . $this->_query_builder['order_by'][1];
        }
        
        return $q;
   }
   
   public function delete(){
        $this->_query_builder = array(
            'delete' => ''
        );
        return $this;
   }
   
   public function select($columns = '*'){
        $this->_query_builder = array(
            'select' => $columns
        );
        return $this;
   }
   
   public function update(){
        $this->_query_builder = array(
            'update' => ''
        );
        return $this;
   }
   
   public function insert(){
        $this->_query_builder = array(
            'insert' => ''
        );
        return $this;
   }
   
   public function into($table_name){
		$this->_query_builder['into'] = $table_name;
   }
   
   public function values(array $values){
		$this->_query_builder['values'] = $values;
   }
   
   public function set($field, $value){
        if(!isset($this->_query_builder['set'])){
            $this->_query_builder['set'] = array();
        }
        
        $this->_query_builder['set'][] = array($field, $value);
        return $this;
   }
   
   public function from($table_name){
        $this->_query_builder['from'] = $table_name;
        return $this;
   }
   
   public function join($table_name){
        if(!isset($this->_query_builder['join'])){
            $this->_query_builder['join'] = array();
        }
        
        $this->_query_builder['join'][] = $table_name;
        return $this;
   }
   
   public function on($fieldname_table_1, $operator, $fieldname_table_2){
        if(!isset($this->_query_builder['join_condition'])){
            $this->_query_builder['join_condition'] = array();
        }
        
        $this->_query_builder['join_condition'][] = $fieldname_table_1 . $condition . $fieldname_table_2;
        return $this;
   }
   
   public function where($condition){
        if(!empty($condition)){
            $this->_query_builder['where'] = array(array($condition, 'and'));    
        }
            
        return $this;
   }
   
   public function andWhere($condition){
        $this->_query_builder['where'][] = array($condition, 'and');
        return $this;
   }
   
   public function orWhere(){
        $this->_query_builder['where'][] = array($condition, 'or');
        return $this;
   }
   
   public function groupBy($fieldname){
        $this->_query_builder['group_by'] = $fieldname;
        return $this;
   }
   
   public function limit($limit){
        $this->_query_builder['limit'] = $limit;
        return $this;
   }
   
   public function orderBy($field, $order){
        $this->_query_builder['order_by'] = array($field, $order);
        return $this;
   }
}
