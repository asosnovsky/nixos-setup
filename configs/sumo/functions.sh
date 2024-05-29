export DEV_DEPLOYMENTS=(stag long)
export PROD_DEPLOYMENTS=(dub fra mon mum prod syd tky us2 fed)
echo "Loading functions"
function airflow-v2-exec-web() {
	dep=${1}
	airflow-v2-exec $dep bash
}
function airflow-v2-exec() {
	dep=${1}
	airflow-v2 $dep exec -it svc/$dep-analytics-airflow-v2-webserver -c webserver -- ${@:2}
}
function tsh.login() {
	tsh login -d --proxy teleport.kumoroku.com eks-${1}
	tsh kube login eks-${1}
}
function tsh.hop() {
    tsh ssh -d --cluster=eks-${1} hop-${2:-1}
}
function tsh.shared() {
    tsh ssh -d --cluster=main shared_box-${2:-1}
}
function tsh.login.all() {
	for dep in ${DEV_DEPLOYMENTS[@]}; do
		echo "---------"
		echo "  $dep   "
		echo "---------"
		tsh.login $dep
	done
	for dep in ${PROD_DEPLOYMENTS[@]}; do
		echo "---------"
		echo "  $dep   "
		echo "---------"
		tsh.login $dep
	done
}
function airflow-v2-all-tasks() {
	for dep in ${DEV_DEPLOYMENTS[@]}; do
		echo "[  $dep   ]"
		airflow-v2-list-tasks $dep
	done
	for dep in ${PROD_DEPLOYMENTS[@]}; do
		echo "[  $dep   ]"
		airflow-v2-list-tasks $dep
	done
}
function airflow-v2-delete-pod-tasks() {
	dep=${1}
	for pod in $(airflow-v2-list-tasks $dep | awk -F ' ' '{print $1}'); do airflow-v2 $dep delete pod/$pod &; done
}
function open-paas() {
	dep=${1:-infrastructure}
	eval $(dev hcvault cli_env -a $dep)
	export GITHUB_TOKEN=$(dev secrets get -s github_token | jq -r .github_token_password)
	paas-iac-shell
}
