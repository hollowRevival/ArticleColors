# --
# Copyright (C) 2026 Katla, https://github.com/hollowRevival/ArticleColors
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::OutputFilter::ArticleColors;

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationChannel',
    'Kernel::System::Ticket::Article',
    'Kernel::System::User',
);

=head1 NAME

Kernel::Output::HTML::OutputFilter::ArticleColors - tags the article list of AgentTicketZoom for colouring

=head1 DESCRIPTION

C<Frontend::Output::FilterElementPost> filter for the template C<AgentTicketZoom>.
It adds two kinds of CSS classes that F<ArticleColors.css> keys on:

=over 4

=item * C<Preset-E<lt>nameE<gt>> on every C<UseArticleColors> container: the agent's personal
preset, or the system-wide C<ArticleColors::ColorPreset> if the agent has none.

=item * C<Channel-E<lt>nameE<gt>> (Email, Internal, Phone, ...) on every article row.

=back

Doing this after rendering, instead of overriding F<AgentTicketZoom.tt>, keeps the package
independent of the core template and of other packages that customise it.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if ref $Param{Data} ne 'SCALAR' || !defined ${ $Param{Data} };

    my $Preset = $Self->_Preset();

    # The filter can see the same markup twice (a template rendered in parts is filtered
    # per part and again as part of the page), so it must skip what is already tagged.
    ${ $Param{Data} } =~ s{ ( class="(?![^"]*\bPreset-)[^"]*\bUseArticleColors\b ) }{$1 Preset-$Preset}gxms;

    # The ticket and article IDs are read from the row's own hidden ArticleInfo link, so no
    # request parameter is needed and TicketID/TicketNumber lookups behave identically.
    ${ $Param{Data} } =~ s{
        ( <tr\ class="(?![^"]*\bChannel-)[^"]* )
        ( "\ id="Row\d+">\s*<td\ class="No">\s*\d+\s*
          <input\ type="hidden"\ class="ArticleInfo"[^>]*?TicketID=(\d+);ArticleID=(\d+); )
    }{
        my ( $RowStart, $RowRest, $TicketID, $ArticleID ) = ( $1, $2, $3, $4 );
        my $Channel = $Self->_ChannelName( TicketID => $TicketID, ArticleID => $ArticleID );
        $Channel ? "$RowStart Channel-$Channel$RowRest" : "$RowStart$RowRest";
    }gexms;

    return 1;
}

sub _Preset {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( $Self->{UserID} ) {
        my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
        my %Preferences = $UserObject->GetPreferences(
            UserID => $Self->{UserID},
        );
        my $UserPreset = $Preferences{UserArticleColorsPreset};

        # The preference group's option list is the allowlist. A stale stored value, or a
        # disabled preference group, must fall through to the system-wide preset.
        my $UserChoices = $ConfigObject->Get('PreferencesGroups')->{ArticleColorsPreset}->{Data} // {};
        return $UserPreset
            if $UserPreset && $UserPreset ne 'UseGlobalDefault' && exists $UserChoices->{$UserPreset};
    }

    my $GlobalPreset = $ConfigObject->Get('ArticleColors::ColorPreset');

    # The value is printed into a class attribute, so it must be a plain word.
    return $GlobalPreset if $GlobalPreset && $GlobalPreset =~ m{\A\w+\z}xms;

    return 'Standard';
}

sub _ChannelName {
    my ( $Self, %Param ) = @_;

    $Self->{ChannelNameByArticle}->{ $Param{TicketID} }
        //= $Self->_ChannelNamesOfTicket( TicketID => $Param{TicketID} );

    return $Self->{ChannelNameByArticle}->{ $Param{TicketID} }->{ $Param{ArticleID} };
}

sub _ChannelNamesOfTicket {
    my ( $Self, %Param ) = @_;

    my $ChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my %ChannelNameByID;
    my %ChannelNameByArticle;

    META_ARTICLE:
    for my $MetaArticle ( $ArticleObject->ArticleList( TicketID => $Param{TicketID} ) ) {
        my $ChannelID = $MetaArticle->{CommunicationChannelID};

        if ( !exists $ChannelNameByID{$ChannelID} ) {
            my %Channel = $ChannelObject->ChannelGet( ChannelID => $ChannelID );
            $ChannelNameByID{$ChannelID} = $Channel{ChannelName} // '';
        }

        # Channel names end up in a class attribute.
        next META_ARTICLE if $ChannelNameByID{$ChannelID} !~ m{\A\w+\z}xms;

        $ChannelNameByArticle{ $MetaArticle->{ArticleID} } = $ChannelNameByID{$ChannelID};
    }

    return \%ChannelNameByArticle;
}

1;
