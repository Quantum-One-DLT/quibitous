use crate::config::SessionSettings;
pub use quibitestkit::console::style;

pub fn print_intro(session_settings: &SessionSettings, name: &str) {
    println!(
        r###"
        ---_ ......._-_--.
       (|\ /      / /| \  \               _  ___  ____  __  __ _   _ _   _  ____    _    _   _ ____  ____
       /  /     .'  -=-'   `.            | |/ _ \|  _ \|  \/  | | | | \ | |/ ___|  / \  | \ | |  _ \|  _ \
      /  /    .'             )        _  | | | | | |_) | |\/| | | | |  \| | |  _  / _ \ |  \| | | | | |_) |
    _/  /   .'        _.)   /        | |_| | |_| |  _ <| |  | | |_| | |\  | |_| |/ ___ \| |\  | |_| |  _ <
   /   o  o       _.-' /  .'          \___/ \___/|_| \_\_|  |_|\___/|_| \_|\____/_/   \_\_| \_|____/|_| \_\
   \          _.-'    / .'#|
    \______.-'//    .'.' \#|         {}
     \|  \ | //   .'.' _ |#|
      `   \|//  .'.'_._._|#|
       .  .// .'.' | _._ \#|
       \`-|\_/ /    \ _._ \#\
        `/'\__/      \ _._ \#\
       /^|            \ _-_ \#
      '  `             \ _-_ \
                        \_

 {}quibitous: {}

###############################################################################
    "###,
        style::binary.apply_to(name),
        *style::icons::quibitous,
        style::binary.apply_to(session_settings.quibitous.to_string_lossy()),
    )
}
