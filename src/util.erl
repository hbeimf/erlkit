-module(util).

-export([ago/1,
         ago/2,
         datetime/1,
         month/1,
         seconds/1,
         timestamp/1,
         flt/1,
         int/1,
         num/1,
         hex/1,
         hexdigit/1,
         unhexdigit/1,
         urlencode/1,
         quote_plus/1,
         revjoin/3,
         lstrip/2,
         rstrip/2,
         strip/2,
         lower/1,
         upper/1]).

-define(QS_SAFE(C), ((C >= $a andalso C =< $z) orelse
                     (C >= $A andalso C =< $Z) orelse
                     (C >= $0 andalso C =< $9) orelse
                     (C =:= $\. orelse C =:= $- orelse C =:= $~ orelse C =:= $_))).

ago(Seconds) ->
    ago(calendar:universal_time(), Seconds).

ago(Time, Seconds) ->
    datetime(seconds(Time) - Seconds).

datetime(Seconds) when is_integer(Seconds) ->
    calendar:gregorian_seconds_to_datetime(Seconds);
datetime(<<Y:4/binary, "/", M:2/binary, "/", D:2/binary, " ", H:2/binary, ":", Mi:2/binary, ":", S:2/binary, _/binary>>) ->
    {{int(Y), int(M), int(D)}, {int(H), int(Mi), int(S)}};
datetime(<<Y:4/binary, "/", M:2/binary, "/", D:2/binary, _/binary>>) ->
    {{int(Y), int(M), int(D)}, {0, 0, 0}};
datetime(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary, " ", H:2/binary, ":", Mi:2/binary, ":", S:2/binary, _/binary>>) ->
    {{int(Y), int(M), int(D)}, {int(H), int(Mi), int(S)}};
datetime(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary, _/binary>>) ->
    {{int(Y), int(M), int(D)}, {0, 0, 0}};
datetime(_) ->
    undefined.

month(<<"Jan">>) -> 1;
month(<<"Feb">>) -> 2;
month(<<"Mar">>) -> 3;
month(<<"Apr">>) -> 4;
month(<<"May">>) -> 5;
month(<<"Jun">>) -> 6;
month(<<"Jul">>) -> 7;
month(<<"Aug">>) -> 8;
month(<<"Sep">>) -> 9;
month(<<"Oct">>) -> 10;
month(<<"Nov">>) -> 11;
month(<<"Dec">>) -> 12;
month(Str) when is_list(Str) ->
    month(list_to_binary(Str)).

seconds(Seconds) when is_integer(Seconds) ->
    Seconds;
seconds(DateTime) ->
    calendar:datetime_to_gregorian_seconds(DateTime).

timestamp({{Y, M, D}, {H, Mi, S}}) ->
    list_to_binary(io_lib:format("~4..0B/~2..0B/~2..0B ~2..0B:~2..0B:~2..0B", [Y, M, D, H, Mi, S])).

flt(Flt) when is_float(Flt) ->
    Flt;
flt(Bin) when is_binary(Bin) ->
    flt(binary_to_list(Bin));
flt(Atom) when is_atom(Atom) ->
    flt(atom_to_list(Atom));
flt(List) when is_list(List) ->
    list_to_float(List).

int(Int) when is_integer(Int) ->
    Int;
int(Bin) when is_binary(Bin) ->
    int(binary_to_list(Bin));
int(Atom) when is_atom(Atom) ->
    int(atom_to_list(Atom));
int(List) when is_list(List) ->
    list_to_integer(List).

num(Num) when is_number(Num) ->
    Num;
num(Any) ->
    try flt(Any) catch error:badarg -> int(Any) end.

hex(List) when is_list(List) ->
    hex(list_to_binary(List));
hex(<<Q:4, Rest/bitstring>>) ->
    <<(hexdigit(Q)), (hex(Rest))/binary>>;
hex(<<>>) ->
    <<>>.

hexdigit(C) when C < 10 -> $0 + C;
hexdigit(C) when C < 16 -> $a + (C - 10).

unhexdigit(C) when C >= $0, C =< $9 -> C - $0;
unhexdigit(C) when C >= $a, C =< $f -> C - $a + 10;
unhexdigit(C) when C >= $A, C =< $F -> C - $A + 10.

urlencode(Props) ->
    RevPairs = lists:foldl(fun ({K, V}, Acc) ->
                                   [[quote_plus(K), $=, quote_plus(V)]|Acc]
                           end, [], Props),
    lists:flatten(revjoin(RevPairs, $&, [])).

quote_plus(Atom) when is_atom(Atom) ->
    quote_plus(atom_to_list(Atom));
quote_plus(Bin) when is_binary(Bin) ->
    quote_plus(binary_to_list(Bin));
quote_plus(Int) when is_integer(Int) ->
    quote_plus(integer_to_list(Int));
quote_plus(String) ->
    quote_plus(String, []).

quote_plus([], Acc) ->
    lists:reverse(Acc);
quote_plus([C|Rest], Acc) when ?QS_SAFE(C) ->
    quote_plus(Rest, [C|Acc]);
quote_plus([$\s|Rest], Acc) ->
    quote_plus(Rest, [$+|Acc]);
quote_plus([C|Rest], Acc) ->
    <<Hi:4, Lo:4>> = <<C>>,
    quote_plus(Rest, [hexdigit(Lo), hexdigit(Hi), $\%|Acc]).

revjoin([], _Separator, Acc) ->
    Acc;
revjoin([S|Rest], Separator, []) ->
    revjoin(Rest, Separator, [S]);
revjoin([S|Rest], Separator, Acc) ->
    revjoin(Rest, Separator, [S, Separator|Acc]).

lstrip([C|Rest], C) ->
    lstrip(Rest, C);
lstrip(<<C, Rest/binary>>, C) ->
    lstrip(Rest, C);
lstrip(Seq, _) ->
    Seq.

rstrip([C|Rest], C) ->
    case rstrip(Rest, C) of
        [] ->
            [];
        Tail  ->
            [C|Tail]
    end;
rstrip([O|Rest], C) ->
    [O|rstrip(Rest, C)];
rstrip(<<_, _/binary>> = Bin, C) when is_binary(Bin) ->
    case binary:last(Bin) of
        C ->
            rstrip(binary:part(Bin, 0, size(Bin) - 1), C);
        _ ->
            Bin
    end;
rstrip(Seq, _) ->
    Seq.

strip(Seq, C) ->
    rstrip(lstrip(Seq, C), C).

lower(Bin) when is_binary(Bin) ->
    unicode:characters_to_binary(lower(unicode:characters_to_list(Bin)));
lower(Str) ->
    string:to_lower(Str).

upper(Bin) when is_binary(Bin) ->
    unicode:characters_to_binary(upper(unicode:characters_to_list(Bin)));
upper(Str) ->
    string:to_upper(Str).
