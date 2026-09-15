<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'music' );

/** MySQL database username */
define( 'DB_USER', 'root' );

/** MySQL database password */
define( 'DB_PASSWORD', '' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '#iSDs8_ne}urlvJm]c+ku;Sg en])_f-f2xGRT,o6B,n}0/yi* NUFe+9.q,Gq1v' );
define( 'SECURE_AUTH_KEY',  'Qg Pnx?!C@NG&Bi,Rm`]o}dJaqOf:M7bPwioMchSq],JsVq LX(L+K,d1x4MlO~7' );
define( 'LOGGED_IN_KEY',    '?;:QKAo=za16%FNb#bND>]Tlep`u(lFqW7t8KQ$C#>{[lFPu~7dzqN3k).c(^%po' );
define( 'NONCE_KEY',        'HYTa5.TZCB36OmNS3][wJQalDmkr.zkccv`<Y=Me2O!+S6Dug+jSZv@t3p#g=?&(' );
define( 'AUTH_SALT',        '}#(iGZDKpszLq?}.ApG)60 LJe8foub:FuK8I@Ao~hk7{fV.hRX[dxImWX2E4^]i' );
define( 'SECURE_AUTH_SALT', '7jx6Xsw#_IRqF4G> 0^<N{6DjEbVl&Y-kJDQo)7f4YIB[5KFO.@b>_/&N9@nyAss' );
define( 'LOGGED_IN_SALT',   'zR3<0GRf5>-B^FYg44>Vw0k^*y(n=%7R!]v_Z2I05U!2y#[rASnEz_wXz6?M<2BI' );
define( 'NONCE_SALT',       'o-p@Z=MLT V1cFdntt)!{*WAMSg0Fy@f:yxz@j_8_3mTgYEneu7xkUC#1H;zfw=w' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
