
# create_posts in wordpress from a postgres database
#     Copyright (C) 2012 James Michael DuPont <jamesmikedupont@gmail.com>

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Affero General Public License as
#     published by the Free Software Foundation, either version 3 of the
#     License, or (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Affero General Public License for more details.

#     You should have received a copy of the GNU Affero General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
# you will  need to change the database connection string.

use DBI;
use Data::Dumper;
use YAML::XS (Load); # apt-get install libyaml-libyaml-perl
use strict;
use warnings;
use Config::Simple; # apt-get install  libconfig-simple-perl

sub Header
{
    my $name =shift;
    my $url =shift;

printf <<END_HEADER, $name,$url,$url,$url;
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0"
	xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:wp="http://wordpress.org/export/1.2/"
>
<channel>
	<title>%s</title>
	<link>%s</link>
	<description>Just another WordPress site</description>
	<pubDate>Fri, 27 Jul 2012 14:05:47 +0000</pubDate>
	<language>en-US</language>
	<wp:wxr_version>1.2</wp:wxr_version>
	<wp:base_site_url>%s</wp:base_site_url>
	<wp:base_blog_url>%s</wp:base_blog_url>
	<wp:author><wp:author_id>1</wp:author_id><wp:author_login>admin</wp:author_login><wp:author_email>jamesmikedupont\@gmail.com</wp:author_email><wp:author_display_name><![CDATA[admin]]></wp:author_display_name><wp:author_first_name><![CDATA[]]></wp:author_first_name><wp:author_last_name><![CDATA[]]></wp:author_last_name></wp:author>
	<generator>http://wordpress.org/?v=3.4.1</generator>

END_HEADER


}


sub Tag {
    my $tag=shift;
    my $format_category=<<END_CATEGORY;
    <category domain="post_tag" nicename="%s"><![CDATA[%s]]></category>
END_CATEGORY
my $tag1 = $tag;
    
    $tag1=~ s/\&/&amp;/g;

printf $format_category,$tag1,$tag;
}


sub Post 
{
    my ($title,$pubdate,$content,$siteurl)=@_;

    
    $title=~ s/\&/&amp;/g;
    $content =~ s/\n/<p\/>/g;

#	print "publish:" .   $post->{'publish_at'} ."\n";
#	print "created:" .   $post->{'2011-10-17 00:46:26.27484'} ."\n";


    my $format= <<END_POST;
	<item>
		<title>%s</title>
		<link>%s?p=1</link>
		<pubDate>%s</pubDate>
		<wp:post_date>%s</wp:post_date>
		<dc:creator>admin</dc:creator>
		<description></description>
		<dc:creator>admin</dc:creator>
		<content:encoded><![CDATA[%s]]></content:encoded>
		<excerpt:encoded><![CDATA[]]></excerpt:encoded>
		<wp:status>publish</wp:status>
		<wp:post_type>post</wp:post_type>
		<wp:comment_status>open</wp:comment_status>
		<wp:ping_status>open</wp:ping_status>
		<wp:status>publish</wp:status>
		<wp:post_name>this does not matter</wp:post_name>
		<wp:post_parent>0</wp:post_parent>
		<wp:menu_order>0</wp:menu_order>
		<wp:post_type>post</wp:post_type>
		<wp:post_password></wp:post_password>
		<wp:is_sticky>0</wp:is_sticky>
END_POST
printf($format,$title,$siteurl,$pubdate,$pubdate,$content);
}

sub EndPost
{
    print "</item>";
}

sub Footer{
     print <<END_FOOTER;
</channel>
</rss>
END_FOOTER

}

sub Comment {
    my $author=shift;
    my $email=shift;
    my $link=shift;
    my $IP=shift;
    my $date=shift;
    my $comment=shift;
    my $xml;
  #http://shibashake.com/wordpress-theme/wordpress-xml-import-format-comments
    $xml .= "<wp:comment>\n";
    $xml .= "<wp:comment_author><![CDATA[" . $author . "]]></wp:comment_author>\n";
    $xml .= "<wp:comment_author_email>" . $email . "</wp:comment_author_email>\n";
    if (!$link){
 	$xml .= "<wp:comment_author_url></wp:comment_author_url>\n";
    }    else    {
	$xml .= "<wp:comment_author_url>http://www.hubpages.com" . $link . "</wp:comment_author_url>\n";
    }

    $xml .= "<wp:comment_author_IP>" . $IP . "</wp:comment_author_IP>\n";
    $xml .= "<wp:comment_date>" . $date . "</wp:comment_date>\n";
#    $xml .= "<wp:comment_date_gmt>" . get_gmt_from_date($date) . "</wp:comment_date_gmt>\n";
    $xml .= "<wp:comment_content><![CDATA[" . $comment . "]]></wp:comment_content>\n";
#    if ($status == "Approved")    {
	$xml .= "<wp:comment_approved>1</wp:comment_approved>\n";
 #   }    else {
#	$xml .= "<wp:comment_approved>0</wp:comment_approved>\n";    }
    $xml .= "<wp:comment_type></wp:comment_type>\n";
    $xml .= "<wp:comment_parent>0</wp:comment_parent>\n";
    $xml .= "<wp:comment_user_id>0</wp:comment_user_id>\n";
    $xml .= "</wp:comment>\n";
    return $xml;
}

sub SubImage
{
    my $data=shift;
    my $type=shift;
    my $site=shift;
    my $body;
    
    return unless ($data->{$type});
    foreach my $obj (@{$data->{$type}})
    {
	my $t=$type;
	$t  =~ s/://;	   
	die unless ($obj);
	die unless ($obj->{url});
	die unless ($obj->{url} =~ /com\/(\w+)\/(\w+)\//);
	my $dir= "$site/$t/$1/$2";
#	    print "mkdir -p $dir\n";	    
#	    $body.= "<img src='"/. $dir . "/" . $obj->{name} .  "'/>\n";
	if ($obj->{name} =~ /.mp4/ )
	{
#	    $body.= "<video src=\'" . $obj->{url} .  "\'/>\n";
	    $body.= "[FMP]" . $obj->{url} .  "[/FMP]\n";
	}
	else
	{
	    $body.= "<img src=\'" . $obj->{url} .  "\'/>\n";
	}
    }
    return $body;
}

sub Images
{
    my $site=shift;
    my $post_id=shift;
    my $data =shift;
    my $body;
    foreach my $type ("large","encode")
    {
	next unless ($data->{$type});
	$body .= SubImage($data,$type,$site);
    }
    return $body if $body;

##########
    foreach my $type (":origin",":original")
    {
	next unless ($data->{$type});
	$body .= SubImage($data,$type,$site);
    }
    warn "Missing large:$post_id";
}

sub Comments {
    my $dbh=shift;
    my $post_id=shift;
    ## now we skip over posts with no comments
    my $comments = $dbh->selectall_hashref("select * from comments where post_id = $post_id","id");
    
    return 0 unless ($comments);
    return 0 unless (%{$comments}); 
    
    
    if ($comments){
	if (%{$comments}){
	    foreach my $id (keys %{$comments})	    {
		my $user = $dbh->selectrow_hashref("select * from users where id = $post_id");
		my $comment=$comments->{$id};
		
#		    warn Dumper($comment);

	#	    if ($comment->{approval_count})
		{
		    my ($author,$email, $link,$IP, $date, $comment_text);	    
		    $author=$user->{username} || $comment->{alt_user_name} || "";
		    $email=$user->{email} || $comment->{alt_user_email} || "";
		    $link="";
		    $IP =$comment->{from_ip}||"";
		    $date = $comment->{created_at}||"";
		    $comment_text=$comment->{body}||"";
		    my $text = Comment ( $author,$email, $link,$IP, $date, $comment_text);
#			warn $text;
		    print $text;
		}
	    }
	}
    }    
    return 1;
}

sub Main {
    my $site_id=shift || die "no site id passed";
    my $cfg = new Config::Simple('app.ini');
    
    my $user = $cfg->param('User')|| die "no user in ini";
    my $pwd = $cfg->param('Password') || die "no pwd in ini";
    my $db = $cfg->param('Database') || die "no DB in ini";
    my $dbh = DBI->connect("dbi:Pg:dbname=$db", $user, $pwd) or die "cannot connect";

    my $ary_ref = $dbh->selectall_arrayref("select a.id, post_id, results, p.site_id from assemblies a join posts p on a.post_id=p.id where kind='encode' and p.site_id=${site_id}");

    my $siteobj = $dbh->selectrow_hashref("select name from sites where id = $site_id");
    my $siteurl = "http://" . $siteobj->{name} . ".com/";

    warn "Found number of items :". scalar(@{$ary_ref}) . " using site name $siteobj->{name} and url $siteurl" ;
 
    Header($siteobj->{name},$siteurl);


    foreach my $item (@{$ary_ref}) 
    {
	my $id = $item->[0];
	my $post_id = $item->[1];
	my $res = $item->[2];
	my $site = $item->[3];
	my $images= Load($res);

	my $body="";

#    warn join (",",sort keys %{$data}) . "\n" ;
	my $post = $dbh->selectrow_hashref("select * from posts where id = $post_id");
	
	my $tags = $dbh->selectall_arrayref("select taggable_id,t.name from taggings o join tags t on t.id= o.tag_id where taggable_id=$post_id group by taggable_id,t.name");

	my $captions = $dbh->selectall_arrayref("select * from captions where post_id = $post_id");
	
	$body .= Images($site,$post_id,$images);
	
# post.subheading
	if ($post->{subheading}){
	    $body .=  "<h6 class='tfsubheading'>" . $post->{subheading} . "</h6>\n";
	}
	
# post.lat_and_long
	if ($post->{lat_and_long}){
	     $body .="latlong" . $post->{lat_and_long} . "\n";
	}
	
# post.captions.
	foreach my $caption (@{$captions})
	{
	     $body .= "<div class='tfcaption'>".  $caption->[1] . "</div>\n";
	}
	#print Dumper({cations=>$captions});
	
# post.tags

	Post( $post->{caption},$post->{'publish_at'}||next , $body,$siteurl);

	Comments($dbh,$post_id);

	if (@{$tags}){
	    foreach my $tag (@{$tags})	{
		Tag($tag->[1]);	    
	    }
	}

	EndPost();
	
    }
    
    Footer();
}

my $siteid=shift @ARGV;
warn "going to run $siteid\n";
Main ($siteid);



#see also 
# http://search.cpan.org/~timb/DBI-1.53/DBI.pm
# http://codex.wordpress.org/Importing_Content#WordPress
# http://wordpress.org/extend/plugins/wordpress-importer/
# http://shibashake.com/wordpress-theme/wordpress-xml-import-format-comments
