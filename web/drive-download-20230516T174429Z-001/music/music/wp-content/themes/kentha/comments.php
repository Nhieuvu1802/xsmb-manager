<?php
/*
Package: kentha
*/


/*
 * If the current post is protected by a password and
 * the visitor has not yet entered the password we will
 * return early without loading the comments.
 */
if ( post_password_required() )
	return;
?>


<?php if ( ( comments_open() || '0' != get_comments_number() ) && post_type_supports( get_post_type(), 'comments' ) ) : ?>
	<div class="qt-vertical-padding-s qt-commentsblock <?php kentha_comment_is_negative(); ?>">
		<h3 class="qt-commentscaption"><span><?php esc_html_e("Comments","kentha"); ?></span></h3>
		<p class="qt-item-metas qt-commentscount">
		<?php 
		/**
		 * [$comments_count amount of comments]
		 * @var [number]
		 *
		 *
		 * NOTE: not using comments_number because escaping string in comments_number produces empty results in some WP installations.
		 */
		$comments_count = wp_count_comments( $id );
		$comments_count = $comments_count->approved;
		switch($comments_count){
			case 0:
				echo esc_html__('This post currently has no comments.', 'kentha');
				break;
			case 1:
				echo esc_html__('This post currently has 1 comment.', 'kentha');
				break;
			default:
				echo esc_html__('This post currently has', 'kentha').' '.esc_html($comments_count).' '.esc_html__('comments.', 'kentha');
		}
		?>
		</p>
	</div>
	<div id="comments" class="comments-area comments-list qt-part-post-comments qt-spacer-s qt-paper qt-paddedcontent qt-card">
		<?php if ( have_comments() ) : ?>
			<?php if ( get_comment_pages_count() > 1 && get_option( 'page_comments' ) ) : // are there comments to navigate through ?>
				<div class="">
					<nav id="comment-nav-above" class="comment-navigation" role="navigation">
						<h3 class="screen-reader-text"><?php esc_html_e( 'Comment navigation', "kentha" ); ?></h3>
						<div class="nav-previous"><?php previous_comments_link( esc_html__( '&larr; Older Comments', "kentha" ) ); ?></div>
						<div class="nav-next"><?php next_comments_link( esc_html__( 'Newer Comments &rarr;', "kentha" ) ); ?></div>
					</nav>
				</div >
			<?php endif; // check for comment navigation ?>
				<ol class="qt-comment-list">
					<?php wp_list_comments( array( 'callback' => 'kentha_s_comment' ) ); ?>
				</ol>
			<?php if ( get_comment_pages_count() > 1 && get_option( 'page_comments' ) ) : // are there comments to navigate through ?>
					
			<nav id="comment-nav-below" class="comment-navigation" role="navigation">
				<h3 class="qw-page-subtitle grey-text"><?php esc_html_e( 'Comment navigation', "kentha" ); ?></h3>
				<div class="nav-previous"><?php previous_comments_link( esc_html__( '&larr; Older Comments', "kentha" ) ); ?></div>
				<div class="nav-next"><?php next_comments_link( esc_html__( 'Newer Comments &rarr;', "kentha" ) ); ?></div>
			</nav><!-- #comment-nav-below -->
				
			<?php endif; // check for comment navigation ?>
		<?php endif; // have_comments() ?>
		
		<?php

		/*
		*
		*     Custom parameters for the comment form
		*
		*/
		$required_text = esc_html__('Required fields are marked *',"kentha");
		if(!isset ($consent) ) { 
			$consent = ''; 
		}
		$args = array(
			'id_form'           	=> 'qw-commentform',
			'id_submit'         	=> 'qw-submit',
			'class_form'			=> 'qt-clearfix',
			'title_reply_to'    	=> esc_html__( 'Leave a Reply to %s', "kentha" ),
			'cancel_reply_before' 	=> '<span class="qt-cancel-reply">',
			'cancel_reply_after'	=> '</span>',
			'cancel_reply_link' 	=> '<span class="qt-btn qt-btn-s"><i class="material-icons">cancel</i> '.esc_html__( 'Cancel', 'kentha' ).'</span>',
			'label_submit'      	=> esc_html__( 'Post Comment' ,"kentha" ),
			'class_submit'			=> 'qt-btn qt-btn-l qt-btn-primary',
			'comment_field' 		=>  '<div class="input-field"><textarea id="comment" name="comment" required="required" class="materialize-textarea"></textarea><label for="comment">'.esc_html__('Comment*',"kentha").'</label></div>',
			'title_reply'       	=> esc_html__( 'Leave a Reply', "kentha" ),
			'title_reply_before' 	=> '<h4 id="reply-title" class="comment-reply-title qt-spacer-s">',
			'title_reply_after' 	=> '</h4>',
			'must_log_in' 			=> '<p class="must-log-in qt-item-metas">' .
				sprintf(
					esc_html__( 'You must be <a href="%s">logged in</a> to post a comment.' , "kentha"),
					wp_login_url( apply_filters( 'the_permalink', esc_url(get_permalink()) ) )
				) . '</p>',
			'logged_in_as' => '<p class="logged-in-as qt-item-metas">' .
				sprintf(
					esc_html__( 'Logged in as ','kentha')
					.' <a href="%1$s">%2$s</a>. '
					.'<a href="%3$s" title="'.esc_html__('Log out of this account','kentha').'">'
					.esc_html__('Log out?','kentha')
					.'</a>'
					.' '.esc_html__("Your email won't be public. Required fields are marked *","kentha"),
					admin_url( 'profile.php' ),
					$user_identity,
					esc_url(wp_logout_url( apply_filters( 'the_permalink', esc_url(get_permalink()) ) ))
				) . '</p>',
			'comment_notes_before' 	=> '',
			'comment_notes_after' 	=> '',
			'fields' 				=> apply_filters( 'comment_form_default_fields', array(
				
				'author'	=> '
					
					<div class="input-field">
						<input id="author" name="author" type="text"  value="' . esc_attr( $commenter['comment_author'] ) .'">
						<label for="author">' . esc_html__( 'Name', "kentha" ).( $req ? '*' : '' ) . '</label>
					</div>',


				'email'   	=> '
					<div class="input-field">
						<input id="email" name="email" type="text" value="' . esc_attr(  $commenter['comment_author_email'] ) .'">
						<label for="email">' . esc_html__( 'Email', "kentha" ).( $req ? '*' : '' ) . '</label>
					</div>',

				'url'     	=> '
					<div class="input-field">
						<input id="url" name="url" type="text" value="' . esc_attr( $commenter['comment_author_url'] ) .'">
						<label for="url">'.esc_html__( 'Website', "kentha" ) . '</label>
					</div>',
				// WP 4.9.6
				'cookies' => 	'
					<div class="input-field">
					<p class="comment-form-cookies-consent"><input id="wp-comment-cookies-consent" name="wp-comment-cookies-consent" type="checkbox" value="yes"' . $consent . ' />' .
					'<label for="wp-comment-cookies-consent">' . esc_html__( 'Save my name, email, and website in this browser for the next time I comment.', 'kentha' ) . '</label></p>
					</div><hr class="qt-spacer-s">',
				)

			),
		);


		// If comments are closed and there are comments, let's leave a little note, shall we?
		if (  comments_open() && post_type_supports( get_post_type(), 'comments' ) ) :?>
			<?php  comment_form($args); ?>
		<?php else: ?>
			<p class="no-comments"><?php esc_attr_e( 'Comments are closed.', "kentha" ); ?></p>
		<?php endif; ?>

	</div><!-- #comments -->
<?php endif; ?>
