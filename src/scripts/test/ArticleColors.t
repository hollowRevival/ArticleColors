# --
# ArticleColors - unit tests for the AgentTicketZoom output filter
# Copyright (C) 2026 Katla, https://github.com/hollowRevival/ArticleColors
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::Output::HTML::OutputFilter::ArticleColors;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $Helper        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $UserObject    = $Kernel::OM->Get('Kernel::System::User');
my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

my $UserLogin = $Helper->TestUserCreate();
my $UserID    = $UserObject->UserLookup( UserLogin => $UserLogin );

my $TicketID = $TicketObject->TicketCreate(
    Title        => 'ArticleColors unit test',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'new',
    CustomerUser => 'unittest',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True( $TicketID, 'Test ticket created' );

my $EmailArticleID = $ArticleObject->BackendForChannel( ChannelName => 'Email' )->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'customer',
    IsVisibleForCustomer => 1,
    From                 => 'customer@example.com',
    To                   => 'support@example.com',
    Subject              => 'Question',
    Body                 => 'Body',
    Charset              => 'utf-8',
    MimeType             => 'text/plain',
    HistoryType          => 'EmailCustomer',
    HistoryComment       => 'unit test',
    UserID               => 1,
);
my $InternalArticleID = $ArticleObject->BackendForChannel( ChannelName => 'Internal' )->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'agent@example.com',
    Subject              => 'Note',
    Body                 => 'Body',
    Charset              => 'utf-8',
    MimeType             => 'text/plain',
    HistoryType          => 'AddNote',
    HistoryComment       => 'unit test',
    UserID               => 1,
);
$Self->True( $EmailArticleID && $InternalArticleID, 'Test articles created' );

my $Row = sub {
    my ( $Number, $ArticleID ) = @_;
    return <<"HTML";
<tr class="agent Outgoing VisibleForCustomer  " id="Row$Number">
    <td class="No">
        $Number
        <input type="hidden" class="ArticleInfo" name="Link$Number" value="/otrs/index.pl?Action=AgentTicketZoom;Subaction=ArticleUpdate;Count=$Number;TicketID=$TicketID;ArticleID=$ArticleID;"/>
HTML
};

my $Page = sub {
    return '<div class="MainBox TicketZoom UseArticleColors">'
        . $Row->( 1, $EmailArticleID )
        . $Row->( 2, $InternalArticleID )
        . '<div class="TimelineView UseArticleColors"></div>';
};

my $Run = sub {
    my $Html   = $Page->();
    my $Filter = Kernel::Output::HTML::OutputFilter::ArticleColors->new( UserID => $UserID );
    $Filter->Run( Data => \$Html );
    return $Html;
};

# Presets: system default, personal choice, "follow default", stale value.
$ConfigObject->Set(
    Key   => 'ArticleColors::ColorPreset',
    Value => 'Soft'
);

my $Html = $Run->();
WrapperCountIs( $Html, 'Preset-Soft', 2, 'System default preset is set on both containers' );

$UserObject->SetPreferences(
    UserID => $UserID,
    Key    => 'UserArticleColorsPreset',
    Value  => 'RedGreenCVD'
);
$Html = $Run->();
WrapperCountIs( $Html, 'Preset-RedGreenCVD', 2, 'Personal preset wins over the system default' );

$UserObject->SetPreferences(
    UserID => $UserID,
    Key    => 'UserArticleColorsPreset',
    Value  => 'UseGlobalDefault'
);
$Html = $Run->();
WrapperCountIs( $Html, 'Preset-Soft', 2, 'UseGlobalDefault follows the system default' );

$UserObject->SetPreferences(
    UserID => $UserID,
    Key    => 'UserArticleColorsPreset',
    Value  => 'Gone" onload="x'
);
$Html = $Run->();
WrapperCountIs( $Html, 'Preset-Soft', 2, 'A stale or hostile stored value falls back to the system default' );
$Self->False( scalar( $Html =~ m{onload}xms ), 'A hostile stored value never reaches the markup' );

$ConfigObject->Set(
    Key   => 'ArticleColors::ColorPreset',
    Value => 'bad value"'
);
$Html = $Run->();
WrapperCountIs( $Html, 'Preset-Standard', 2, 'An unusable system value falls back to Standard' );

# Channel classes.
$Self->True(
    scalar( $Html =~ m{<tr\ class="agent\ Outgoing\ VisibleForCustomer\ \ \ Channel-Email"\ id="Row1"}xms ),
    'Email article row gets Channel-Email'
);
$Self->True(
    scalar( $Html =~ m{<tr\ class="agent\ Outgoing\ VisibleForCustomer\ \ \ Channel-Internal"\ id="Row2"}xms ),
    'Internal article row gets Channel-Internal'
);

# Idempotency: filtering already filtered markup must not add the classes again.
my $Filter = Kernel::Output::HTML::OutputFilter::ArticleColors->new( UserID => $UserID );
my $Twice  = $Html;
$Filter->Run( Data => \$Twice );
$Self->Is( $Twice, $Html, 'Running the filter on its own output changes nothing' );

# A row of an unknown article is left alone.
my $Unknown = $Row->( 9, 999999999 );
$Filter->Run( Data => \$Unknown );
$Self->False( scalar( $Unknown =~ m{Channel-}xms ), 'Row of an unknown article gets no channel class' );

# No-op on non-scalar-ref data.
$Self->True( $Filter->Run( Data => 'not a ref' ), 'Run tolerates unusable Data' );

sub WrapperCountIs {
    my ( $Html, $Class, $Expected, $Name ) = @_;
    my $Count = () = $Html =~ m{UseArticleColors\ \Q$Class\E"}gxms;
    $Self->Is( $Count, $Expected, $Name );
    return;
}

1;
