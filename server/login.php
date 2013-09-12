<?php
    $name = $_POST['name'];
    $pass = $_POST['pass'];
    $users = parse_ini_file("user.ini", true);
    if (isset($users[$name]) && $users[$name]['pass'] == $pass) {
        $result = array('ok'   => true, 
                        'name' => $name,
                        'dir'  => $users[$name]['dir']);
        echo json_encode($result);
    } else {
        $result = array('ok'  => false, 
                        'err' => 'no user named '.$name.'');
        echo json_encode($result);
    }
?>
