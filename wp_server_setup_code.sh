############################Checking the user is root or not###########################################
echo "Checking the user is root or not"
	if [[ $EUID -ne 0 ]]; then
	echo "Please run this script as a root"
    exit 1
    else
        echo "User is root"
		echo "Updating and Upgrading the packages, Hence might take some time. Please do not terminate the script!!"
        apt-get update && apt-get upgrade -y
        sleep 1
    fi
############################Checking Nginx And Installing if not present##########################
        echo "Checking Nginx"
			if [[ -e /var/run/nginx.pid && -e /etc/nginx/nginx.conf ]];
				then
                    echo "nginx is running and configured according to scripts requirement"
                else
                        apt-get purge nginx nginx-common -y && apt-get autoremove -y && apt-get autoclean -y
                        sleep 1
						echo "Downloading Nginx - Please do not interrupt the process or kill it"
                        wget -P / -q http://nginx.org/download/nginx-1.19.6.tar.gz
                        sleep 1
                        echo "Installing Required Compilers and Packages that are needed by nginx"
						sleep 1
						apt-get install build-essential -y
						sleep 1
						echo "Installing LIBPCRE ZLIB SSL-LIB'S"
						sleep 1
						apt-get install libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev -y
						echo "Now all the dependent packages that are required by Nginx are installed. Hence Unzipping the Nginx and Installing it"
						cd /
						echo "Unzipping the Nginx downloaded Tar format into the Root folder( / )"
						sleep 1
						tar -zxvf /nginx-1.19.6.tar.gz
						cd /nginx-1.19.6
						./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_image_filter_module=dynamic --modules-path=/etc/nginx/modules --with-http_v2_module
						make
						make install
						sleep 1
						echo "To know where are the configuration files are placed kindly use command ->nginx -V"
						echo "The below output will show that the Nginx has started and Master and Worker processes are running"
						nginx
						systemctl enable nginx && systemctl restart nginx
						ps -ef|grep nginx
						sleep 1				
            fi
# ###########################Checking PHP And Installing if not present##########################	
		echo "Checking PHP is present or not"
				php_check=$(php -v|wc -l)
				if [[ $php_check -gt 1 && -e /var/run/php ]];
				then
					echo "PHP is present according to the requirement of the script"
				else
		echo "Reinstalling PHP and PHP-MySql and PHP-FPM - do not interrupt the process"
				apt-get purge php php-fpm php-gd php-mysql -y && apt-get autoremove -y && apt-get autoclean -y
				sleep1
				apt-get install php php-fpm php-mysql php-gd -y
				sleep 1
				chmod 777 /var/run/php/*
				fi
				php_sock=$(ls -ltr /var/run/php|grep www|cut -d" " -f10)
# ##########################Checking MySql And Installing if not present###########################
		echo "Checking if MySql Exists or not "
				service mysql start
				mysql_check=$(ps -ef|grep mysql|wc -l)
				if [[ $mysql_check -gt 1 && -e /etc/mysql/mysql.cnf ]];
				then
				echo "MySql is Present"
				phpenmod mysqli
				else
		echo "Reinstalling Mysql Mysqli do not stop or interrupt the process"
				sleep 1
				apt-get purge mysql mysqli -y && apt-get autoremove -y && apt-get autoclean -y
				apt-get install mysql mysqli -y
				service mysql start
				phpenmod mysqli
				
				fi
##############Prompting user to input a valid domain name and creating an entry on /etc/hosts once domain name is validated############################
		echo "Enter Domain name"
				read dom_name
				regx='^[a-zA-Z0-9][a-zA-Z0-9-][a-zA-Z0-9.]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,6}$'
				while [[ !( $dom_name =~ $regx ) ]];
				do
				echo "Enter a Proper Domain name"
				read dom_name
				done
				echo "Now the enetered Domain name -> $dom_name looks good"
		echo "Creating an Entry in /etc/hosts"
				sleep 1
				echo "127.0.0.1  $dom_name" >> /etc/hosts
############### Creating Nginx.conf file ############################################
		echo "Now Creating a Wordpress Setup...Please do not interrupt"
				sleep 1
				wget -P /site/ -q http://wordpress.org/latest.zip
				unzip /site/latest.zip -d /site/
		echo "Creating Nginx Conf file"
				sleep 1
				echo "
				user www-data;
				worker_processes auto;
				events {}
				http {
				include mime.types;
				gzip on;
				gzip_comp_level 3;
				gzip_types text/css;
				gzip_types text/javascript;
				fastcgi_cache_path /tmp/nginx levels=1:2 keys_zone=zone_1:100m inactive=4m;
				fastcgi_cache_key "$scheme$request_method$host$request_uri";
				add_header X-Cache $upstream_cache_status;
				server {
				listen 80;
				server_name $dom_name;
				root /site/wordpress;
				index index.php index.html;
				location ~\.php$ {
				include fastcgi.conf;
				fastcgi_pass unix:/run/php/$php_sock;
				fastcgi_cache zone_1;
				fastcgi_cache_valid 200 4m;
				}
				}
				}" > /etc/nginx/nginx.conf
		echo "Rebouncing Nginx"
				sleep 1
				systemctl reload nginx
######################## Extracting name for the Database ################################
				db_name=${dom_name%%.*}_db
				user_name=user1
				password=someday123
				echo "$db_name is your Database Name"
				echo "Creating a Database for your site"
				mysql -e "create database $db_name;"
				mysql -e "create user $user_name@localhost IDENTIFIED BY '$password';"
				mysql -e "grant all privileges on $db_name to '$user_name'@'localhost';"
				mysql -e "flush privileges;"
######################## Creating wp-config.php file for Database connectivity ##################
				touch /site/wordpress/wp-config.php
				echo "
				define( 'DB_NAME', '$db_name' );
				define( 'DB_USER', '$user_name' );
				define( 'DB_PASSWORD', '$password' );
				define( 'DB_HOST', 'localhost' );
				define( 'DB_CHARSET', 'utf8mb4' );
				define( 'DB_COLLATE', '' );
				define( 'AUTH_KEY',         '^_V {CeeRYO]Pieq$6!q_kXua/lituKF~Anj{y-0%^V)[KxA_4Nh+Ko^)NYo97F+' );
				define( 'SECURE_AUTH_KEY',  'oIifl#6v=V9.1ww4>)v.%lG<YLo0bcdz_zy@I&o8pR)$3d5$b}H[66xc{$Z{vZJL' );
				define( 'LOGGED_IN_KEY',    '6TMVY%i{Ov20ew2NnG1|)3n9MAv<hR%HO,<WX0YGG4#`Y|+zswBdp830w >Gk[q#' );
				define( 'NONCE_KEY',        '>?66=V+4XqyixcXoEtP4t[xG><#I+c5+zEr7K~IrFj>Id$iPiBg]E-L[/Kp75u@ ' );
				define( 'AUTH_SALT',        '1l~]#,4wpmn+EH]yO7X9Znl[b7~aLHF +$<PuP=cTYnr.]yfx6]6~T:*J7OmiojO' );
				define( 'SECURE_AUTH_SALT', '!enI!?ysaDa&0 4m@J,m!;U=p{vXQj]]T}K/+!rvX9,L1$r{^kpRCbNrsm[SJO`$' );
				define( 'LOGGED_IN_SALT',   '-U)F@ld+1~:g~*!0X,HRSwH83Bh_hU:ic[aw6(*Bc&!vsdM2!bZ].s)p?:~w(p_?' );
				define( 'NONCE_SALT',       '>Bts/T6eCr?9XkqiWXC+=t[m@}.-Z*^0c4.f&8yKI^>D?ltBsS;g6@Dp.mE=}=A|' );
				$table_prefix = 'wp_';
				define( 'WP_DEBUG', false );
				define( 'WP_DEBUG', false );
				if ( ! defined( 'ABSPATH' ) ) {
				define( 'ABSPATH', __DIR__ . '/' );
				}
				require_once ABSPATH . 'wp-settings.php';
				" > /site/wordpress/wp-config.php
				sleep 1
				echo "Your Website is believed to be ready now!!"
				systemctl reload nginx
######################### Finally the Big Bad script Ends!! ############################
			echo "Everything is Hopefully fine...Fingers Crossed"
			echo "Please type your Domain name on the Browsers Address Bar correctly"

