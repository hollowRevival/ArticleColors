# --
# Copyright (C) 2026 Katla, https://github.com/hollowRevival/ArticleColors
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Language::sv_ArticleColors;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my %Translation = (
        'Loads the ArticleColors stylesheet in AgentTicketZoom.' => 'Läser in ArticleColors stilmall i AgentTicketZoom.',
        'Color preset for the article list in AgentTicketZoom. Used for all agents who have not picked their own preset in their personal preferences. The three color vision presets are designed for red-green, blue-yellow and total color blindness.'
            => 'Färgpreset för artikellistan i AgentTicketZoom. Gäller alla agenter som inte valt ett eget preset i sina personliga inställningar. De tre färgseendepresetsen är gjorda för rödgrön, blågul och total färgblindhet.',
        'Lets each agent pick their own article list color preset in the personal preferences, instead of always following ArticleColors::ColorPreset. The keys of the Data hash are also the presets the output filter accepts.'
            => 'Låter varje agent välja eget färgpreset för artikellistan i personliga inställningar, i stället för att alltid följa ArticleColors::ColorPreset. Nycklarna i Data-hashen är också de preset som utskriftsfiltret accepterar.',
        'Adds the color preset and channel classes that the ArticleColors stylesheet uses to the article list of AgentTicketZoom.'
            => 'Lägger till de färgpreset- och kanalklasser som ArticleColors stilmall använder i artikellistan i AgentTicketZoom.',
        'Article list colors' => 'Färgpreset (artikelfärger)',
        'Choose your own color preset for the article list in the ticket view, or follow the system default.'
            => 'Välj ditt eget färgpreset för artikellistan i ärendevyn, eller följ systemets standardval.',
        'Use the system default'                              => 'Använd systemets standardval',
        'Standard (default colors)'                            => 'Standard (grundprofil)',
        'High contrast (more saturated colors)'               => 'Kontrast (mer mättade färger)',
        'Soft (less saturated colors)'                        => 'Mjuk (lägre mättnad)',
        'Cool (blue and purple instead of green and teal)'    => 'Kylig (blå/lila i stället för grön/teal)',
        'Red-green color blindness (protanopia/deuteranopia)' => 'Rödgrön färgblindhet (protanopi/deuteranopi)',
        'Blue-yellow color blindness (tritanopia)'            => 'Blågul färgblindhet (tritanopi)',
        'Total color blindness (patterns instead of colors)'  => 'Total färgblindhet (mönster i stället för färg)',
    );

    $Self->{Translation} = { %{ $Self->{Translation} // {} }, %Translation };

    return;
}

1;
