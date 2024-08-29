use leptos::*;
use leptos_meta::*;
use leptos_router::*;
use pulldown_cmark::{html, Parser};

use crate::api::select_post;

#[component]
pub fn Component() -> impl IntoView {
    let params = use_params_map();
    let slug = move || params.with(|params| params.get("slug").cloned().unwrap_or_default());
    let post = create_blocking_resource(
        || (),
        move |_| async move { select_post(slug()).await.unwrap() },
    );

    view! {
        <Suspense fallback=|| ()>
            {post
                .get()
                .unwrap_or_default()
                .tags
                .into_iter()
                .map(|tag| {
                    view! { <Meta name=tag.to_string() content=tag.to_string() /> }
                })
                .collect::<Vec<_>>()}
            {move || {
                post.with(|post| {
                    let post = post.clone().unwrap_or_default();
                    let markdown_input = post.body.to_string();
                    let parser = Parser::new(&markdown_input);
                    let mut html_output = String::new();
                    html::push_html(&mut html_output, parser);
                    view! {
                        <article>
                            <div class="flex max-w-3xl mx-auto flex-col gap-4">
                                <p class="text-4xl font-semibold">{post.title.clone()}</p>
                                <div class="flex gap-3 justify-start items-center text-sm text-muted-foreground">
                                    <p
                                        on:click=move |e| {
                                            e.stop_propagation();
                                            if let Some(github) = &post.author.github {
                                                let _ = window()
                                                    .open_with_url_and_target(&github, "_blank");
                                            }
                                        }
                                        class="cursor-pointer hover:underline"
                                    >
                                        {"by "}
                                        <span class="ml-1 font-semibold">
                                            {&post.author.name.to_string()}
                                        </span>
                                    </p>
                                    <p>{post.created_at}</p>
                                    <p>{format!("{} min read", post.read_time)}</p>
                                    <p>{format!("{} views", post.total_views)}</p>
                                </div>
                            </div>
                            <div
                                class="my-6 prose max-w-3xl mx-auto prose-h3:text-white prose-code:before:content-none prose-code:after:content-none prose-code:text-[#ffbd2e] prose-strong:text-white prose-h1:text-white prose-h1:text-3xl prose-h2:text-white prose-h2:text-2xl prose-ul:text-white prose-p:text-white prose-a:text-[#ffbd2e]"
                                inner_html=html_output
                            />

                        </article>
                    }
                })
            }}
        </Suspense>
    }
}
