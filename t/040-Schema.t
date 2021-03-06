#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 12;
use strict;
use warnings;

### Tests for adding relationships -- one to many (result_as all)

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'DBIx::Mint::Schema';
}

{
    package Bloodbowl::Coach; use Moo;
    with 'DBIx::Mint::Table';
    
    has id           => ( is => 'rw', predicate => 1 );
    has name         => ( is => 'rw' );
    has email        => ( is => 'rw' );
    has password     => ( is => 'rw' );
}
{
    package Bloodbowl::Team; use Moo;
    with 'DBIx::Mint::Table';

    has id           => ( is => 'rw' );
    has name         => ( is => 'rw' );
    has coach        => ( is => 'rw' );
}
{
    package Bloodbowl::Player; use Moo;
    with 'DBIx::Mint::Table';

    has id           => ( is => 'rw' );
    has name         => ( is => 'rw' );
    has position     => ( is => 'rw' );
    has team         => ( is => 'rw' );
}

my $schema = DBIx::Mint::Schema->instance;
isa_ok( $schema, 'DBIx::Mint::Schema');

$schema->add_class(
    class    => 'Bloodbowl::Coach',
    table    => 'coaches',
    pk       => 'id',
    auto_pk  => 1
);

$schema->add_class(
    class    => 'Bloodbowl::Team',
    table    => 'teams',
    pk       => 'id',
    auto_pk  => 1
);

$schema->add_class(
    class    => 'Bloodbowl::Player',
    table    => 'players',
    pk       => 'id',
    auto_pk  => 1
);

# This is a one-to-many relationship...
$schema->add_relationship(
    from_class     => 'Bloodbowl::Team',
    to_class       => 'Bloodbowl::Player',
    to_field       => 'team',
    method         => 'get_players',
    result_as      => 'all',
    inverse_method => 'get_team',
    inv_result_as  => 'single',
);

can_ok('Bloodbowl::Team',    'get_players' );
can_ok('Bloodbowl::Player',  'get_team'    );

# Database connection
my $mint = Test::DB->connect_db;
ok( DBIx::Mint->instance->has_connector,    'Mint has a database connection');

{
    my $team = Bloodbowl::Team->find(1);
    isa_ok($team, 'Bloodbowl::Team');
    my @players = $team->get_players;
    is @players, 5,                         'The relationship from->to returns all the objects';
    isa_ok $players[0], 'Bloodbowl::Player';
    is $players[0]->name, 'player1',        'The returned object are correct';
}
{
    my $player = Bloodbowl::Player->find(3);
    is $player->name, 'player3',            'Retrieved an object from the database';
    my $team   = $player->get_team;
    is $team->name, 'Tinieblas',            'Relationship to->from returns a single object';
}

done_testing();
